# frozen_string_literal: true

# == VerifiesWithEmail
#
# Controller concern to handle verification by email
module VerifiesWithEmail
  extend ActiveSupport::Concern
  include ActionView::Helpers::DateHelper
  include SessionsHelper

  included do
    prepend_before_action :verify_with_email, only: :create, unless: -> { skip_verify_with_email? }
  end

  def verify_with_email
    return unless user = find_user || find_verification_user
    return unless user.active?

    if session[:verification_user_id] && token = verification_params[:verification_token].presence
      # The verification token is submitted, verify it
      verify_token(user, token)
    elsif require_email_verification_enabled?(user)
      # Limit the amount of password guesses, since we now display the email verification page
      # when the password is correct, which could be a giveaway when brute-forced.
      return render_sign_in_rate_limited if check_rate_limit!(:user_sign_in, scope: user) { true }

      # Verify the email if the user has logged in successfully.
      verify_email(user) if user.valid_password?(user_params[:password])
    end
  end

  def resend_verification_code
    return unless user = find_verification_user

    if send_rate_limited?(user)
      render_send_rate_limited
    else
      secondary_email = user_secondary_email(user, email_params[:email])

      if email_params[:email].present? && secondary_email.present?
        lock_and_send_verification_instructions(user, secondary_email: secondary_email)
      elsif email_params[:email].blank?
        lock_and_send_verification_instructions(user)
      end

      render json: { status: :success }
    end
  end

  def successful_verification
    session.delete(:verification_user_id)
    @redirect_url = after_sign_in_path_for(current_user) # rubocop:disable Gitlab/ModuleWithInstanceVariables

    render layout: 'minimal'
  end

  private

  def skip_verify_with_email?
    two_factor_enabled? || Gitlab::Qa.request?(request.user_agent)
  end

  def find_verification_user
    return unless session[:verification_user_id]

    User.find_by_id(session[:verification_user_id])
  end

  def lock_and_send_verification_instructions(user, secondary_email: nil, reason: nil)
    service = Users::EmailVerification::GenerateTokenService.new(attr: :unlock_token, user: user)
    raw_token, encrypted_token = service.execute
    user.unlock_token = encrypted_token
    user.lock_access!({ send_instructions: false, reason: reason })
    send_verification_instructions_email(user, raw_token, secondary_email)
  end

  def send_verification_instructions_email(user, token, secondary_email)
    email = secondary_email || user.email
    Notify.verification_instructions_email(email, token: token).deliver_later

    log_verification(user, :instructions_sent)
  end

  # As this is a prepended controller action, we only want to block
  # log in if the VerifiesWithEmail is required
  def requires_verify_email?(user)
    user.access_locked? || user.unlock_token || !trusted_ip_address?(user)
  end

  def verify_email(user)
    return true unless requires_verify_email?(user)

    # If they've received too many codes already, we won't send more
    unless send_rate_limited?(user)
      # If access is locked but there's no unlock_token, or the token has
      # expired, send a new one
      if user.access_locked?
        if !user.unlock_token || unlock_token_expired?(user) # rubocop:disable Style/IfUnlessModifier -- This is easier to read
          lock_and_send_verification_instructions(user)
        end
      # If they're not already locked but from a new IP, lock and send a
      # code
      elsif !trusted_ip_address?(user)
        lock_and_send_verification_instructions(
          user,
          reason: 'sign in from untrusted IP address'
        )
      end
    end

    # At this point they have a non-expired token in their email inbox.
    # Prompt for them to enter it.
    prompt_for_email_verification(user)
  end

  def verify_token(user, token)
    service = Users::EmailVerification::ValidateTokenService.new(attr: :unlock_token, user: user, token: token)
    result = service.execute

    if result[:status] == :success
      handle_verification_success(user)
      render json: { status: :success, redirect_path: users_successful_verification_path }
    else
      handle_verification_failure(user, result[:reason], result[:message])
      render json: result
    end
  end

  def render_sign_in_rate_limited
    message = format(
      s_('IdentityVerification|Maximum login attempts exceeded. Wait %{interval} and try again.'),
      interval: rate_limit_interval(:user_sign_in)
    )
    redirect_to new_user_session_path, alert: message
  end

  def render_send_rate_limited
    message = format(
      s_("IdentityVerification|You've reached the maximum amount of resends. Wait %{interval} and try again."),
      interval: rate_limit_interval(:email_verification_code_send)
    )
    render json: { status: :failure, message: message }
  end

  def rate_limit_interval(rate_limit)
    interval_in_seconds = Gitlab::ApplicationRateLimiter.rate_limits[rate_limit][:interval]
    distance_of_time_in_words(interval_in_seconds)
  end

  def send_rate_limited?(user)
    Gitlab::ApplicationRateLimiter.throttled?(:email_verification_code_send, scope: user)
  end

  def handle_verification_failure(user, reason, message)
    user.errors.add(:base, message)
    log_verification(user, :failed_attempt, reason)
  end

  def handle_verification_success(user)
    user.unlock_access!
    log_verification(user, :successful)

    sign_in(user)

    log_audit_event(current_user, user, with: authentication_method)
    log_user_activity(user)
    verify_known_sign_in
  end

  def trusted_ip_address?(user)
    AuthenticationEvent.initial_login_or_known_ip_address?(user, request.ip)
  end

  def prompt_for_email_verification(user)
    session[:verification_user_id] = user.id
    self.resource = user
    add_gon_variables # Necessary to set the sprite_icons path, since we skip the ApplicationController before_filters

    render 'devise/sessions/email_verification'
  end

  def verification_params
    params.require(:user).permit(:verification_token)
  end

  def email_params
    params.require(:user).permit(:email)
  end

  def user_secondary_email(user, email)
    user.emails.confirmed.find_by_email(email)&.email
  end

  def log_verification(user, event, reason = nil)
    Gitlab::AppLogger.info(
      message: 'Email Verification',
      event: event.to_s.titlecase,
      username: user.username,
      ip: request.ip,
      reason: reason.to_s
    )
  end

  def require_email_verification_enabled?(user)
    ::Gitlab::CurrentSettings.require_email_verification_on_account_locked &&
      Feature.disabled?(:skip_require_email_verification, user, type: :ops)
  end

  def unlock_token_expired?(user)
    Users::EmailVerification::ValidateTokenService.new(
      attr: :unlock_token,
      user: user,
      # We explicitly pass nil - we're only checking expiry, not the
      # token itself
      token: nil
    ).expired_token?
  end
end

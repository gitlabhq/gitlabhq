# frozen_string_literal: true

# == VerifiesWithEmail
#
# Controller concern to handle verification by email
module VerifiesWithEmail
  extend ActiveSupport::Concern
  include ActionView::Helpers::DateHelper

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
      message = format(
        s_("IdentityVerification|You've reached the maximum amount of resends. Wait %{interval} and try again."),
        interval: rate_limit_interval(:email_verification_code_send)
      )
      render json: { status: :failure, message: message }
    else
      secondary_email = user_secondary_email(user, email_params[:email])

      if email_params[:email].present? && secondary_email.present?
        send_verification_instructions(user, secondary_email: secondary_email)
      elsif email_params[:email].blank?
        send_verification_instructions(user)
      end

      render json: { status: :success }
    end
  end

  def update_email
    return unless user = find_verification_user

    log_verification(user, :email_update_requested)
    result = Users::EmailVerification::UpdateEmailService.new(user: user).execute(email: email_params[:email])

    if result[:status] == :success
      send_verification_instructions(user)
    else
      handle_verification_failure(user, result[:reason], result[:message])
    end

    render json: result
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

  def send_verification_instructions(user, secondary_email: nil, reason: nil)
    service = Users::EmailVerification::GenerateTokenService.new(attr: :unlock_token, user: user)
    raw_token, encrypted_token = service.execute
    user.unlock_token = encrypted_token
    user.lock_access!({ send_instructions: false, reason: reason })
    send_verification_instructions_email(user, raw_token, secondary_email)
  end

  def send_verification_instructions_email(user, token, secondary_email)
    email = secondary_email || verification_email(user)
    Notify.verification_instructions_email(email, token: token).deliver_later

    log_verification(user, :instructions_sent)
  end

  def verify_email(user)
    if user.unlock_token
      # Prompt for the token if it already has been set. If the token has expired, send a new one.
      send_verification_instructions(user) if unlock_token_expired?(user)
      prompt_for_email_verification(user)
    elsif user.access_locked? || !trusted_ip_address?(user)
      # require email verification if:
      # - their account has been locked because of too many failed login attempts, or
      # - they have logged in before, but never from the current ip address
      reason = 'sign in from untrusted IP address' unless user.access_locked?
      send_verification_instructions(user, reason: reason) unless send_rate_limited?(user)
      prompt_for_email_verification(user)
    end
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
    user.confirm if unconfirmed_verification_email?(user)
    user.email_reset_offered_at = Time.current if user.email_reset_offered_at.nil?
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
    Feature.enabled?(:require_email_verification, user) &&
      Feature.disabled?(:skip_require_email_verification, user, type: :ops)
  end

  def unlock_token_expired?(user)
    return false unless user.locked_at

    user.locked_at < Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES.minutes.ago
  end
end

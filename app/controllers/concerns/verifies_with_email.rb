# frozen_string_literal: true

# == VerifiesWithEmail
#
# Controller concern to handle verification by email
module VerifiesWithEmail
  extend ActiveSupport::Concern
  include ActionView::Helpers::DateHelper

  included do
    prepend_before_action :verify_with_email, only: :create, unless: -> { skip_verify_with_email? }
    skip_before_action :required_signup_info, only: :successful_verification
  end

  def verify_with_email
    return unless user = find_user || find_verification_user

    if session[:verification_user_id] && token = verification_params[:verification_token].presence
      # The verification token is submitted, verify it
      verify_token(user, token)
    elsif require_email_verification_enabled?(user)
      # Limit the amount of password guesses, since we now display the email verification page
      # when the password is correct, which could be a giveaway when brute-forced.
      return render_sign_in_rate_limited if check_rate_limit!(:user_sign_in, scope: user) { true }

      if user.valid_password?(user_params[:password])
        # The user has logged in successfully.
        if user.unlock_token
          # Prompt for the token if it already has been set
          prompt_for_email_verification(user)
        elsif user.access_locked? || !trusted_ip_address?(user)
          # require email verification if:
          # - their account has been locked because of too many failed login attempts, or
          # - they have logged in before, but never from the current ip address
          send_verification_instructions(user)
          prompt_for_email_verification(user)
        end
      end
    end
  end

  def resend_verification_code
    return unless user = find_verification_user

    send_verification_instructions(user)
    prompt_for_email_verification(user)
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

  # After successful verification and calling sign_in, devise redirects the
  # user to this path. Override it to show the successful verified page.
  def after_sign_in_path_for(resource)
    if action_name == 'create' && session[:verification_user_id] == resource.id
      return users_successful_verification_path
    end

    super
  end

  def send_verification_instructions(user)
    return if send_rate_limited?(user)

    service = Users::EmailVerification::GenerateTokenService.new(attr: :unlock_token, user: user)
    raw_token, encrypted_token = service.execute
    user.unlock_token = encrypted_token
    user.lock_access!({ send_instructions: false })
    send_verification_instructions_email(user, raw_token)
  end

  def send_verification_instructions_email(user, token)
    return unless user.can?(:receive_notifications)

    Notify.verification_instructions_email(user.email, token: token).deliver_later

    log_verification(user, :instructions_sent)
  end

  def verify_token(user, token)
    service = Users::EmailVerification::ValidateTokenService.new(attr: :unlock_token, user: user, token: token)
    result = service.execute

    if result[:status] == :success
      handle_verification_success(user)
    else
      handle_verification_failure(user, result[:reason], result[:message])
    end
  end

  def render_sign_in_rate_limited
    message = format(
      s_('IdentityVerification|Maximum login attempts exceeded. Wait %{interval} and try again.'),
      interval: user_sign_in_interval
    )
    redirect_to new_user_session_path, alert: message
  end

  def user_sign_in_interval
    interval_in_seconds = Gitlab::ApplicationRateLimiter.rate_limits[:user_sign_in][:interval]
    distance_of_time_in_words(interval_in_seconds)
  end

  def send_rate_limited?(user)
    Gitlab::ApplicationRateLimiter.throttled?(:email_verification_code_send, scope: user)
  end

  def handle_verification_failure(user, reason, message)
    user.errors.add(:base, message)
    log_verification(user, :failed_attempt, reason)

    prompt_for_email_verification(user)
  end

  def handle_verification_success(user)
    user.unlock_access!
    log_verification(user, :successful)

    sign_in(user)
  end

  def trusted_ip_address?(user)
    return true if Feature.disabled?(:check_ip_address_for_email_verification)

    AuthenticationEvent.initial_login_or_known_ip_address?(user, request.ip)
  end

  def prompt_for_email_verification(user)
    session[:verification_user_id] = user.id
    self.resource = user

    render 'devise/sessions/email_verification'
  end

  def verification_params
    params.require(:user).permit(:verification_token)
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
end

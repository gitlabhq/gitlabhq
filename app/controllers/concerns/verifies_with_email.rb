# frozen_string_literal: true

# == VerifiesWithEmail
#
# Controller concern to handle verification by email
module VerifiesWithEmail
  extend ActiveSupport::Concern
  include ActionView::Helpers::DateHelper

  TOKEN_LENGTH = 6
  TOKEN_VALID_FOR_MINUTES = 60

  included do
    prepend_before_action :verify_with_email, only: :create, unless: -> { two_factor_enabled? }
  end

  def verify_with_email
    return unless user = find_user || find_verification_user

    if session[:verification_user_id] && token = verification_params[:verification_token].presence
      # The verification token is submitted, verify it
      verify_token(user, token)
    elsif require_email_verification_enabled?
      # Limit the amount of password guesses, since we now display the email verification page
      # when the password is correct, which could be a giveaway when brute-forced.
      return render_sign_in_rate_limited if check_rate_limit!(:user_sign_in, scope: user) { true }

      if user.valid_password?(user_params[:password])
        # The user has logged in successfully.
        if user.unlock_token
          # Prompt for the token if it already has been set
          prompt_for_email_verification(user)
        elsif user.access_locked? || !AuthenticationEvent.initial_login_or_known_ip_address?(user, request.ip)
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

  def find_verification_user
    return unless session[:verification_user_id]

    User.find_by_id(session[:verification_user_id])
  end

  # After successful verification and calling sign_in, devise redirects the
  # user to this path. Override it to show the successful verified page.
  def after_sign_in_path_for(resource)
    if action_name == 'create' && session[:verification_user_id]
      return users_successful_verification_path
    end

    super
  end

  def send_verification_instructions(user)
    return if send_rate_limited?(user)

    raw_token, encrypted_token = generate_token
    user.unlock_token = encrypted_token
    user.lock_access!({ send_instructions: false })
    send_verification_instructions_email(user, raw_token)
  end

  def send_verification_instructions_email(user, token)
    return unless user.can?(:receive_notifications)

    Notify.verification_instructions_email(
      user.id,
      token: token,
      expires_in: TOKEN_VALID_FOR_MINUTES).deliver_later

    log_verification(user, :instructions_sent)
  end

  def verify_token(user, token)
    return handle_verification_failure(user, :rate_limited) if verification_rate_limited?(user)
    return handle_verification_failure(user, :invalid) unless valid_token?(user, token)
    return handle_verification_failure(user, :expired) if expired_token?(user)

    handle_verification_success(user)
  end

  def generate_token
    raw_token = SecureRandom.random_number(10**TOKEN_LENGTH).to_s.rjust(TOKEN_LENGTH, '0')
    encrypted_token = digest_token(raw_token)
    [raw_token, encrypted_token]
  end

  def digest_token(token)
    Devise.token_generator.digest(User, :unlock_token, token)
  end

  def render_sign_in_rate_limited
    message = s_('IdentityVerification|Maximum login attempts exceeded. '\
      'Wait %{interval} and try again.') % { interval: user_sign_in_interval }
    redirect_to new_user_session_path, alert: message
  end

  def user_sign_in_interval
    interval_in_seconds = Gitlab::ApplicationRateLimiter.rate_limits[:user_sign_in][:interval]
    distance_of_time_in_words(interval_in_seconds)
  end

  def verification_rate_limited?(user)
    Gitlab::ApplicationRateLimiter.throttled?(:email_verification, scope: user.unlock_token)
  end

  def send_rate_limited?(user)
    Gitlab::ApplicationRateLimiter.throttled?(:email_verification_code_send, scope: user)
  end

  def expired_token?(user)
    user.locked_at < (Time.current - TOKEN_VALID_FOR_MINUTES.minutes)
  end

  def valid_token?(user, token)
    user.unlock_token == digest_token(token)
  end

  def handle_verification_failure(user, reason)
    message = case reason
              when :rate_limited
                s_("IdentityVerification|You've reached the maximum amount of tries. "\
                   'Wait %{interval} or resend a new code and try again.') % { interval: email_verification_interval }
              when :expired
                s_('IdentityVerification|The code has expired. Resend a new code and try again.')
              when :invalid
                s_('IdentityVerification|The code is incorrect. Enter it again, or resend a new code.')
              end

    user.errors.add(:base, message)
    log_verification(user, :failed_attempt, reason)

    prompt_for_email_verification(user)
  end

  def email_verification_interval
    interval_in_seconds = Gitlab::ApplicationRateLimiter.rate_limits[:email_verification][:interval]
    distance_of_time_in_words(interval_in_seconds)
  end

  def handle_verification_success(user)
    user.unlock_access!
    log_verification(user, :successful)

    sign_in(user)
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

  def require_email_verification_enabled?
    Feature.enabled?(:require_email_verification)
  end
end

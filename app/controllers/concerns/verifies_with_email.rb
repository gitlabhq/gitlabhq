# frozen_string_literal: true

# == VerifiesWithEmail
#
# Controller concern to handle verification by email
module VerifiesWithEmail
  extend ActiveSupport::Concern
  include ActionView::Helpers::DateHelper
  include VerifiesWithEmailHelper

  VERIFICATION_REASON_UNTRUSTED_IP = 'sign in from untrusted IP address'
  VERIFICATION_REASON_NEW_TOKEN_NEEDED = 'new unlock token needed'
  VERIFICATION_REASON_EMAIL_OTP = 'email_otp'
  VERIFICATION_REASON_LOCK_RESEND = 'resend lock verification code'
  VERIFICATION_REASON_EMAIL_OTP_RESEND = 'resend email_otp code'

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
    # Only a user who has started email verification can request a
    # resend
    return unless user = find_verification_user

    if send_rate_limited?(user)
      render_send_rate_limited
    else
      # If an email is provided, validate that it belongs to the user.
      # It is nil otherwise.
      secondary_email = fetch_confirmed_user_secondary_email(user, email_params[:email])
      primary_email = user.email

      # Both `send_` methods will regenerate the respective code, making
      # the old one invalid.
      # Only send email OTP when they're not locked and the FF is still
      # enabled.
      if !treat_as_locked?(user)
        if Feature.enabled?(:email_based_mfa, user)
          send_otp_with_email(
            user,
            secondary_email: secondary_email,
            reason: VERIFICATION_REASON_EMAIL_OTP_RESEND
          )
        else
          render json: {
            status: :failure,
            message: s_('IdentityVerification|Email Verification has ' \
              'been disabled and resending a code is not required. ' \
              'Log in again.')
          }
          return
        end
      # Only lock & send when they are locked.
      else
        lock_and_send_verification_instructions(
          user,
          secondary_email: secondary_email,
          reason: VERIFICATION_REASON_LOCK_RESEND
        )
      end

      if secondary_email.present? && secondary_email != primary_email
        send_notification_to_primary_email(primary_email, secondary_email)
      end

      render json: { status: :success }
    end
  end

  def successful_verification
    session.delete(:verification_user_id)
    @redirect_url = after_sign_in_path_for(current_user) # rubocop:disable Gitlab/ModuleWithInstanceVariables

    render layout: 'minimal'
  end

  def skip_verification_for_now
    return respond_422 unless user = find_verification_user
    return render_403 unless permitted_to_skip_email_otp_in_grace_period?(user)

    handle_verification_success(
      user,
      :skipped,
      'user chose to skip verification in grace period'
    )

    render json: {
      status: :success,
      redirect_path: users_skip_verification_confirmation_path
    }
  end

  def skip_verification_confirmation
    if permitted_to_view_skip_verification_confirmation?
      render 'skip_verification_confirmation',
        layout: 'minimal',
        locals: {
          redirect_url: after_sign_in_path_for(current_user),
          email_otp_required_after: current_user.email_otp_required_after
        }

      # remove verification_user_id from session to indicate that skip verification workflow is done
      # this ensures the confirmation page cannot be visited by user manually navigating to this path
      session.delete(:verification_user_id)
    else
      render json: { status: :failure }
    end
  end

  def fallback_to_email_otp
    return respond_422 unless user = find_user

    if fallback_to_email_otp_permitted?(user)
      clear_two_factor_attempt!
      session[:verification_user_id] = user.id
      resend_verification_code
    else
      render json: { success: false, message: _('Not permitted.') }, status: :bad_request
    end
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
    send_verification_instructions_email(user, raw_token, secondary_email, reason)
  end

  def send_verification_instructions_email(user, token, secondary_email, reason)
    email = secondary_email || user.email
    Notify.verification_instructions_email(email, token: token).deliver_later

    log_verification(user, :instructions_sent, reason)
  end

  def send_otp_with_email(user, secondary_email: nil, reason: VERIFICATION_REASON_EMAIL_OTP)
    service = Users::EmailVerification::GenerateTokenService.new(attr: :email_otp, user: user)
    raw_token, encrypted_token = service.execute

    user.email_otp = encrypted_token
    user.email_otp_last_sent_at = Time.current
    user.email_otp_last_sent_to = secondary_email || user.email

    # The login flow is a critical path.
    # Similar to how Devise's lock & unlock use `save(validate:false),
    # we also will fall back to saving without validation. This reduces
    # the likelihood of an unrelated validation error cascading into a
    # bug that prevents users from being able to sign in.
    # However we will capture the error so that we can fix it.
    begin
      user.save!
    rescue ActiveRecord::RecordInvalid => e
      log_verification(user, :error, e.to_s)
      user.save(validate: false)
    end

    send_verification_instructions_email(user, raw_token, secondary_email, reason)
  end

  # As this is a prepended controller action, we only want to block
  # log in if the VerifiesWithEmail is required
  def requires_verify_email?(user)
    treat_as_locked?(user) || !trusted_ip_address?(user) || require_email_based_otp?(user)
  end

  def send_notification_to_primary_email(primary_email, secondary_email)
    Notify.verification_instructions_sent_to_secondary_email(primary_email, secondary_email).deliver_later
  end

  def verify_email(user)
    return true unless requires_verify_email?(user)

    # If they've received too many codes already, we won't send more
    unless send_rate_limited?(user)
      # If access is locked but there's no unlock_token, or the token has
      # expired, send a new one
      if treat_as_locked?(user)
        if !user.unlock_token || token_expired?(user, :unlock_token)
          lock_and_send_verification_instructions(user, reason: VERIFICATION_REASON_NEW_TOKEN_NEEDED)
        end
      # If they're not already locked but from a new IP, lock and send a
      # code
      elsif !trusted_ip_address?(user)
        lock_and_send_verification_instructions(
          user,
          reason: VERIFICATION_REASON_UNTRUSTED_IP
        )
      elsif require_email_based_otp?(user)
        # We don't lock accounts for Email-based MFA. We just require
        # the token for successful sign in.
        send_otp_with_email(user) if !user.email_otp || token_expired?(user, :email_otp)
      end
    end

    # At this point they have a non-expired token in their email inbox.
    # Prompt for them to enter it.
    prompt_for_email_verification(user)
  end

  # Checks whether email-based OTP is required for the current sign-in
  # attempt.
  #
  # This feature uses a two-part rollout mechanism:
  #   - Feature Flag acts as a kill switch that can be quickly disabled
  #     via ChatOps
  #   - User enrollment is controlled by setting the attribute
  #     email_otp_required_after
  #
  # This allows us to halt or revert the rollout immediately while
  # preserving per-user enrollment dates.
  #
  # Later, the Feature Flag will be changed to an ApplicationSetting so
  # that self-managed administrators can turn this feature on after
  # validating that they have mail delivery correctly configured.
  def require_email_based_otp?(user)
    return false unless Feature.enabled?(:email_based_mfa, user)

    password_based_login? &&
      # Skip on first log in (which occurs for most during account
      # creation), to avoid double email verification with
      # Devise::Confirmable
      user.last_sign_in_at.present? &&
      user.email_otp_required_after.present? &&
      (user.email_otp_required_after <= Time.zone.now || in_email_otp_grace_period?(user))
  end

  def verify_token(user, token)
    # Account locks take precendent over Email-based OTP. If the account
    # is locked, they need to receive and enter their unlock token.
    validation_attr = if treat_as_locked?(user)
                        :unlock_token
                      else
                        :email_otp
                      end

    service = Users::EmailVerification::ValidateTokenService.new(attr: validation_attr, user: user, token: token)
    result = service.execute

    if result[:status] == :success
      handle_verification_success(user, :successful)
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

  def handle_verification_success(user, verification_result, log_message = '')
    # Unlock the user
    user.unlock_access!
    # If an email-otp was set, e.g. by this or a concurrent sign in
    # attempt, clear it, so that a new sign in must be performed.
    user.update(email_otp: nil)
    log_verification(user, verification_result, log_message)

    sign_in(user)

    log_audit_event(current_user, user, with: authentication_method)
    log_user_activity(user)
    verify_known_sign_in
  end

  def permitted_to_view_skip_verification_confirmation?
    current_user &&
      Feature.enabled?(:email_based_mfa, current_user) &&
      permitted_to_skip_email_otp_in_grace_period?(current_user) &&
      # User should not be able to visit users_skip_verification_confirmation_path after
      # finishing token verification OR after completing the skip verification workflow
      session[:verification_user_id]
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

  # This method must return nil if email is not confirmed and belonging
  # to user
  def fetch_confirmed_user_secondary_email(user, email)
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

  def token_expired?(user, attr)
    Users::EmailVerification::ValidateTokenService.new(
      attr: attr,
      user: user,
      # We explicitly pass nil - we're only checking expiry, not the
      # token itself
      token: nil
    ).expired_token?
  end
end

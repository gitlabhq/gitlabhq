# frozen_string_literal: true

# == AuthenticatesWithTwoFactor
#
# Controller concern to handle two-factor authentication
module AuthenticatesWithTwoFactor
  extend ActiveSupport::Concern
  include Authn::WebauthnInstrumentation

  # Store the user's ID in the session for later retrieval and render the
  # two factor code prompt
  #
  # The user must have been authenticated with a valid login and password
  # before calling this method!
  #
  # user - User record
  #
  # Returns nil
  def prompt_for_two_factor(user)
    @user = user # rubocop:disable Gitlab/ModuleWithInstanceVariables -- Set @user for Devise views

    return handle_locked_user(user) unless user.can?(:log_in)

    session[:otp_user_id] = user.id
    session[:user_password_hash] = Digest::SHA256.hexdigest(user.encrypted_password)

    add_gon_variables
    setup_webauthn_authentication(user)

    render 'devise/sessions/two_factor'
  end

  def prompt_for_passwordless_authentication_via_passkey
    add_gon_variables
    setup_passkey_authentication

    render 'devise/sessions/passkeys'
  end

  def handle_locked_user(user)
    clear_two_factor_attempt!

    locked_user_redirect(user)
  end

  def locked_user_redirect(user)
    redirect_to new_user_session_path, alert: locked_user_redirect_alert(user)
  end

  def handle_passwordless_flow
    if passwordless_passkey_params[:device_response].present?
      authenticate_with_passwordless_authentication_via_passkey
    else
      prompt_for_passwordless_authentication_via_passkey
    end
  end

  def authenticate_with_two_factor
    user = self.resource = find_user
    return handle_locked_user(user) unless user.can?(:log_in)
    return handle_changed_user(user) if user_password_changed?(user)

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_otp(user)
    elsif user_params[:device_response].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_webauthn(user)
    elsif user && user.valid_password?(user_params[:password])
      prompt_for_two_factor(user)
    end
  rescue ActiveRecord::RecordInvalid => e
    # We expect User to always be valid.
    # Otherwise, raise internal server error instead of unprocessable entity to improve observability/alerting
    if e.record.is_a?(User)
      raise e.message
    else
      raise e
    end
  end

  private

  def locked_user_redirect_alert(user)
    if user.access_locked?
      _('Your account is locked.')
    elsif !user.confirmed?
      I18n.t('devise.failure.unconfirmed')
    else
      _('Invalid login or password')
    end
  end

  def clear_two_factor_attempt!
    session.delete(:otp_user_id)
    session.delete(:user_password_hash)
    session.delete(:challenge)
  end

  def authenticate_with_two_factor_via_otp(user)
    if valid_otp_attempt?(user)
      # Remove any lingering user data from login
      clear_two_factor_attempt!

      remember_me(user) if user_params[:remember_me] == '1'
      user.save!
      sign_in(user, message: :two_factor_authenticated, event: :authentication)
    else
      send_two_factor_otp_attempt_failed_email(user)
      handle_two_factor_failure(user, 'OTP', _('Invalid two-factor code.'))
    end
  end

  def authenticate_with_two_factor_via_webauthn(user)
    if passkey_via_2fa_enabled?(user)
      # Passkeys would be the default 2FA option so we can reasonably assume it'll be used
      track_passkey_internal_event(
        event_name: 'authenticate_passkey',
        status: 0,
        entry_point: 3,
        user: current_user
      )
    end

    result = Webauthn::AuthenticateService.new(user, user_params[:device_response], session[:challenge]).execute

    if result.success?
      handle_two_factor_success(user)
    else
      handle_two_factor_failure(user, 'WebAuthn', result.message)
    end
  end

  def authenticate_with_passwordless_authentication_via_passkey
    track_passkey_internal_event(
      event_name: 'authenticate_passkey',
      status: 0,
      entry_point: 4
    )

    result = Authn::Passkey::AuthenticateService.new(
      passwordless_passkey_params[:device_response],
      session[:challenge]
    ).execute

    if result.success?
      handle_passwordless_auth_with_passkey_success(result.payload)
    else
      handle_passwordless_auth_with_passkey_failure('WebAuthn', result.message)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def setup_webauthn_authentication(user)
    if user.second_factor_webauthn_registrations.present?

      webauthn_registration_ids = if passkey_via_2fa_enabled?(user)
                                    user.get_all_webauthn_credential_ids
                                  else
                                    user.second_factor_webauthn_registrations.pluck(:credential_xid)
                                  end

      get_options = WebAuthn::Credential.options_for_get(
        allow: webauthn_registration_ids,
        user_verification: 'discouraged',
        extensions: { appid: WebAuthn.configuration.origin }
      )
      session[:challenge] = get_options.challenge
      gon.push(webauthn: { options: Gitlab::Json.dump(get_options) })
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def setup_passkey_authentication
    get_options = WebAuthn::Credential.options_for_get(
      allow: [],
      user_verification: 'required'
    )

    session[:challenge] = get_options.challenge
    gon.push(webauthn: { options: Gitlab::Json.dump(get_options) })
  end

  def handle_two_factor_success(user)
    if passkey_via_2fa_enabled?(user)
      # Passkeys would be the default 2FA option so we can reasonably assume it'll be used
      track_passkey_internal_event(
        event_name: 'authenticate_passkey',
        status: 1,
        user: current_user
      )
    end

    # Remove any lingering user data from login
    clear_two_factor_attempt!

    remember_me(user) if user_params[:remember_me] == '1'
    sign_in(user, message: :two_factor_authenticated, event: :authentication)
  end

  def handle_two_factor_failure(user, method, message)
    if passkey_via_2fa_enabled?(user)
      # Passkeys would be the default 2FA option so we can reasonably assume it'll be used
      track_passkey_internal_event(
        event_name: 'authenticate_passkey',
        status: 2,
        user: current_user
      )
    end

    user.increment_failed_attempts!
    log_failed_two_factor(user, method)

    Gitlab::AppLogger.info("Failed Login: user=#{user.username} ip=#{request.remote_ip} method=#{method}")
    flash.now[:alert] = message
    prompt_for_two_factor(user)
  end

  def handle_passwordless_auth_with_passkey_success(user)
    track_passkey_internal_event(
      event_name: 'authenticate_passkey',
      status: 1,
      user: current_user
    )

    clear_two_factor_attempt!

    remember_me(user) if passwordless_passkey_params[:remember_me] == '1'
    sign_in(user)

    redirect_to root_path || stored_redirect_uri
  end

  def handle_passwordless_auth_with_passkey_failure(method, message)
    track_passkey_internal_event(
      event_name: 'authenticate_passkey',
      status: 2
    )

    Gitlab::AppLogger.info(
      message: "Failed Login",
      login_method: method,
      remote_ip: request.remote_ip
    )

    flash.now[:alert] = message
    prompt_for_passwordless_authentication_via_passkey
  end

  def send_two_factor_otp_attempt_failed_email(user)
    user.notification_service.two_factor_otp_attempt_failed(user, request.remote_ip)
  end

  def log_failed_two_factor(user, method)
    # overridden in EE
  end

  def handle_changed_user(user)
    clear_two_factor_attempt!

    redirect_to new_user_session_path, alert: _('An error occurred. Please sign in again.')
  end

  # If user has been updated since we validated the password,
  # the password might have changed.
  def user_password_changed?(user)
    return false unless session[:user_password_hash]

    Digest::SHA256.hexdigest(user.encrypted_password) != session[:user_password_hash]
  end

  def passkey_via_2fa_enabled?(user)
    Feature.enabled?(:passkeys, user) && user.two_factor_enabled? && user.passkeys_enabled?
  end

  def destroy_all_but_current_user_session!(user, session)
    ActiveSession.destroy_all_but_current(user, session)
  end
end

AuthenticatesWithTwoFactor.prepend_mod_with('AuthenticatesWithTwoFactor')

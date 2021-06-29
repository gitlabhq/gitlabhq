# frozen_string_literal: true

# == AuthenticatesWithTwoFactor
#
# Controller concern to handle two-factor authentication
module AuthenticatesWithTwoFactor
  extend ActiveSupport::Concern

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
    # Set @user for Devise views
    @user = user # rubocop:disable Gitlab/ModuleWithInstanceVariables

    return handle_locked_user(user) unless user.can?(:log_in)

    session[:otp_user_id] = user.id
    session[:user_password_hash] = Digest::SHA256.hexdigest(user.encrypted_password)
    push_frontend_feature_flag(:webauthn)

    if user.two_factor_webauthn_enabled?
      setup_webauthn_authentication(user)
    else
      setup_u2f_authentication(user)
    end

    render 'devise/sessions/two_factor'
  end

  def handle_locked_user(user)
    clear_two_factor_attempt!

    locked_user_redirect(user)
  end

  def locked_user_redirect(user)
    redirect_to new_user_session_path, alert: locked_user_redirect_alert(user)
  end

  def authenticate_with_two_factor
    user = self.resource = find_user
    return handle_locked_user(user) unless user.can?(:log_in)
    return handle_changed_user(user) if user_password_changed?(user)

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_otp(user)
    elsif user_params[:device_response].present? && session[:otp_user_id]
      if user.two_factor_webauthn_enabled?
        authenticate_with_two_factor_via_webauthn(user)
      else
        authenticate_with_two_factor_via_u2f(user)
      end
    elsif user && user.valid_password?(user_params[:password])
      prompt_for_two_factor(user)
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
      handle_two_factor_failure(user, 'OTP', _('Invalid two-factor code.'))
    end
  end

  # Authenticate using the response from a U2F (universal 2nd factor) device
  def authenticate_with_two_factor_via_u2f(user)
    if U2fRegistration.authenticate(user, u2f_app_id, user_params[:device_response], session[:challenge])
      handle_two_factor_success(user)
    else
      handle_two_factor_failure(user, 'U2F', _('Authentication via U2F device failed.'))
    end
  end

  def authenticate_with_two_factor_via_webauthn(user)
    if Webauthn::AuthenticateService.new(user, user_params[:device_response], session[:challenge]).execute
      handle_two_factor_success(user)
    else
      handle_two_factor_failure(user, 'WebAuthn', _('Authentication via WebAuthn device failed.'))
    end
  end

  # Setup in preparation of communication with a U2F (universal 2nd factor) device
  # Actual communication is performed using a Javascript API
  # rubocop: disable CodeReuse/ActiveRecord
  def setup_u2f_authentication(user)
    key_handles = user.u2f_registrations.pluck(:key_handle)
    u2f = U2F::U2F.new(u2f_app_id)

    if key_handles.present?
      sign_requests = u2f.authentication_requests(key_handles)
      session[:challenge] ||= u2f.challenge
      gon.push(u2f: { challenge: session[:challenge], app_id: u2f_app_id,
                      sign_requests: sign_requests })
    end
  end

  def setup_webauthn_authentication(user)
    if user.webauthn_registrations.present?

      webauthn_registration_ids = user.webauthn_registrations.pluck(:credential_xid)

      get_options = WebAuthn::Credential.options_for_get(allow: webauthn_registration_ids,
                                                         user_verification: 'discouraged',
                                                         extensions: { appid: WebAuthn.configuration.origin })

      session[:credentialRequestOptions] = get_options
      session[:challenge] = get_options.challenge
      gon.push(webauthn: { options: get_options.to_json })
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def handle_two_factor_success(user)
    # Remove any lingering user data from login
    clear_two_factor_attempt!

    remember_me(user) if user_params[:remember_me] == '1'
    sign_in(user, message: :two_factor_authenticated, event: :authentication)
  end

  def handle_two_factor_failure(user, method, message)
    user.increment_failed_attempts!
    log_failed_two_factor(user, method)

    Gitlab::AppLogger.info("Failed Login: user=#{user.username} ip=#{request.remote_ip} method=#{method}")
    flash.now[:alert] = message
    prompt_for_two_factor(user)
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
end

AuthenticatesWithTwoFactor.prepend_mod_with('AuthenticatesWithTwoFactor')

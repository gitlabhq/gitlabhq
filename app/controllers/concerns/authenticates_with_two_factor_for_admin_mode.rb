# frozen_string_literal: true

module AuthenticatesWithTwoFactorForAdminMode
  extend ActiveSupport::Concern

  included do
    include AuthenticatesWithTwoFactor
  end

  def admin_mode_prompt_for_two_factor(user)
    return handle_locked_user(user) unless user.can?(:log_in)

    session[:otp_user_id] = user.id
    push_frontend_feature_flag(:webauthn)

    if user.two_factor_webauthn_enabled?
      setup_webauthn_authentication(user)
    else
      setup_u2f_authentication(user)
    end

    render 'admin/sessions/two_factor', layout: 'application'
  end

  def admin_mode_authenticate_with_two_factor
    user = current_user

    return handle_locked_user(user) unless user.can?(:log_in)

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      admin_mode_authenticate_with_two_factor_via_otp(user)
    elsif user_params[:device_response].present? && session[:otp_user_id]
      if user.two_factor_webauthn_enabled?
        admin_mode_authenticate_with_two_factor_via_webauthn(user)
      else
        admin_mode_authenticate_with_two_factor_via_u2f(user)
      end
    elsif user && user.valid_password?(user_params[:password])
      admin_mode_prompt_for_two_factor(user)
    else
      invalid_login_redirect
    end
  end

  def admin_mode_authenticate_with_two_factor_via_otp(user)
    if valid_otp_attempt?(user)
      # Remove any lingering user data from login
      session.delete(:otp_user_id)

      user.save! unless Gitlab::Database.read_only?

      # The admin user has successfully passed 2fa, enable admin mode ignoring password
      enable_admin_mode
    else
      user.increment_failed_attempts!
      Gitlab::AppLogger.info("Failed Admin Mode Login: user=#{user.username} ip=#{request.remote_ip} method=OTP")
      flash.now[:alert] = _('Invalid two-factor code.')

      admin_mode_prompt_for_two_factor(user)
    end
  end

  def admin_mode_authenticate_with_two_factor_via_u2f(user)
    if U2fRegistration.authenticate(user, u2f_app_id, user_params[:device_response], session[:challenge])
      admin_handle_two_factor_success
    else
      admin_handle_two_factor_failure(user, 'U2F')
    end
  end

  def admin_mode_authenticate_with_two_factor_via_webauthn(user)
    if Webauthn::AuthenticateService.new(user, user_params[:device_response], session[:challenge]).execute
      admin_handle_two_factor_success
    else
      admin_handle_two_factor_failure(user, 'WebAuthn')
    end
  end

  private

  def enable_admin_mode
    if current_user_mode.enable_admin_mode!(skip_password_validation: true)
      redirect_to redirect_path, notice: _('Admin mode enabled')
    else
      invalid_login_redirect
    end
  end

  def invalid_login_redirect
    flash.now[:alert] = _('Invalid login or password')
    render :new
  end

  def admin_handle_two_factor_success
    # Remove any lingering user data from login
    session.delete(:otp_user_id)
    session.delete(:challenge)

    # The admin user has successfully passed 2fa, enable admin mode ignoring password
    enable_admin_mode
  end

  def admin_handle_two_factor_failure(user, method)
    user.increment_failed_attempts!
    Gitlab::AppLogger.info("Failed Admin Mode Login: user=#{user.username} ip=#{request.remote_ip} method=#{method}")
    flash.now[:alert] = _('Authentication via %{method} device failed.') % { method: method }

    admin_mode_prompt_for_two_factor(user)
  end
end

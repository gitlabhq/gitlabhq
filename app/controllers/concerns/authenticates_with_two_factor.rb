# == AuthenticatesWithTwoFactor
#
# Controller concern to handle two-factor authentication
#
# Upon inclusion, skips `require_no_authentication` on `:create`.
module AuthenticatesWithTwoFactor
  extend ActiveSupport::Concern

  included do
    # This action comes from DeviseController, but because we call `sign_in`
    # manually, not skipping this action would cause a "You are already signed
    # in." error message to be shown upon successful login.
    skip_before_action :require_no_authentication, only: [:create], raise: false
  end

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
    return locked_user_redirect(user) unless user.can?(:log_in)

    session[:otp_user_id] = user.id
    setup_u2f_authentication(user)
    render 'devise/sessions/two_factor'
  end

  def locked_user_redirect(user)
    flash.now[:alert] = 'Invalid Login or password'
    render 'devise/sessions/new'
  end

  def authenticate_with_two_factor
    user = self.resource = find_user
    return locked_user_redirect(user) unless user.can?(:log_in)

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_otp(user)
    elsif user_params[:device_response].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_u2f(user)
    elsif user && user.valid_password?(user_params[:password])
      prompt_for_two_factor(user)
    end
  end

  private

  def authenticate_with_two_factor_via_otp(user)
    if valid_otp_attempt?(user)
      # Remove any lingering user data from login
      session.delete(:otp_user_id)

      remember_me(user) if user_params[:remember_me] == '1'
      user.save!
      sign_in(user)
    else
      user.increment_failed_attempts!
      Gitlab::AppLogger.info("Failed Login: user=#{user.username} ip=#{request.remote_ip} method=OTP")
      flash.now[:alert] = 'Invalid two-factor code.'
      prompt_for_two_factor(user)
    end
  end

  # Authenticate using the response from a U2F (universal 2nd factor) device
  def authenticate_with_two_factor_via_u2f(user)
    if U2fRegistration.authenticate(user, u2f_app_id, user_params[:device_response], session[:challenge])
      # Remove any lingering user data from login
      session.delete(:otp_user_id)
      session.delete(:challenge)

      remember_me(user) if user_params[:remember_me] == '1'
      sign_in(user)
    else
      user.increment_failed_attempts!
      Gitlab::AppLogger.info("Failed Login: user=#{user.username} ip=#{request.remote_ip} method=U2F")
      flash.now[:alert] = 'Authentication via U2F device failed.'
      prompt_for_two_factor(user)
    end
  end

  # Setup in preparation of communication with a U2F (universal 2nd factor) device
  # Actual communication is performed using a Javascript API
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
end

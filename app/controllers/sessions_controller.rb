class SessionsController < Devise::SessionsController
  prepend_before_action :authenticate_with_two_factor, only: [:create]

  # This action comes from DeviseController, but because we call `sign_in`
  # manually inside `authenticate_with_two_factor`, not skipping this action
  # would cause a "You are already signed in." error message to be shown upon
  # successful login.
  skip_before_action :require_no_authentication, only: [:create]

  def new
    redirect_path =
      if request.referer.present? && (params['redirect_to_referer'] == 'yes')
        referer_uri = URI(request.referer)
        if referer_uri.host == Gitlab.config.gitlab.host
          referer_uri.path
        else
          request.fullpath
        end
      else
        request.fullpath
      end

    # Prevent a 'you are already signed in' message directly after signing:
    # we should never redirect to '/users/sign_in' after signing in successfully.
    unless redirect_path == new_user_session_path
      store_location_for(:redirect, redirect_path)
    end

    if Gitlab.config.ldap.enabled
      @ldap_servers = Gitlab::LDAP::Config.servers
    end

    super
  end

  def create
    super do |resource|
      # User has successfully signed in, so clear any unused reset token
      if resource.reset_password_token.present?
        resource.update_attributes(reset_password_token: nil,
                                   reset_password_sent_at: nil)
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:login, :password, :remember_me, :otp_attempt)
  end

  def find_user
    if user_params[:login]
      User.by_login(user_params[:login])
    elsif user_params[:otp_attempt] && session[:otp_user_id]
      User.find(session[:otp_user_id])
    end
  end

  def authenticate_with_two_factor
    user = self.resource = find_user

    return unless user && user.otp_required_for_login

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      if valid_otp_attempt?(user)
        # Remove any lingering user data from login
        session.delete(:otp_user_id)

        sign_in(user) and return
      else
        flash.now[:alert] = 'Invalid two-factor code.'
        render :two_factor and return
      end
    else
      if user && user.valid_password?(user_params[:password])
        # Save the user's ID to session so we can ask for a one-time password
        session[:otp_user_id] = user.id
        render :two_factor and return
      end
    end
  end

  def valid_otp_attempt?(user)
    user.valid_otp?(user_params[:otp_attempt]) ||
    user.invalidate_otp_backup_code!(user_params[:otp_attempt])
  end
end

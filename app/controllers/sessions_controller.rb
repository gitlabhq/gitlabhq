class SessionsController < Devise::SessionsController
  prepend_before_action :authenticate_with_two_factor, only: :create

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
      # Remove any lingering user data from login
      session.delete(:user)

      # User has successfully signed in, so clear any unused reset tokens
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

  def authenticate_with_two_factor
    @user = User.by_login(user_params[:login])

    if user_params[:otp_attempt].present? && session[:user]
      if valid_otp_attempt?
        # Insert the saved params from the session into the request parameters
        # so they're available to Devise::Strategies::DatabaseAuthenticatable
        request.params[:user].merge!(session[:user])
      else
        @error = 'Invalid two-factor code'
        render :two_factor and return
      end
    else
      if @user && @user.valid_password?(user_params[:password])
        self.resource = @user

        if resource.otp_required_for_login
          # Login is valid, save the values to the session so we can prompt the
          # user for a one-time password.
          session[:user] = user_params
          render :two_factor and return
        end
      end
    end
  end

  def valid_otp_attempt?
    @user.valid_otp?(user_params[:otp_attempt]) ||
    @user.invalidate_otp_backup_code!(user_params[:otp_attempt])
  end
end

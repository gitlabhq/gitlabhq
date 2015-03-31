class SessionsController < Devise::SessionsController
  prepend_before_filter :two_factor_enabled?, only: :create

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
    unless redirect_path == '/users/sign_in'
      store_location_for(:redirect, redirect_path)
    end

    if Gitlab.config.ldap.enabled
      @ldap_servers = Gitlab::LDAP::Config.servers
    end

    super
  end

  def create
    super do |resource|
      # User has successfully signed in, so clear any unused reset tokens
      if resource.reset_password_token.present?
        resource.update_attributes(reset_password_token: nil,
                                   reset_password_sent_at: nil)
      end
    end
  end

  private

  def two_factor_enabled?
    user_params = params[:user]
    @user = User.by_login(user_params[:login])

    if user_params[:otp_attempt].present?
      unless @user.valid_otp?(user_params[:otp_attempt]) ||
        @user.recovery_code?(user_params[:otp_attempt])
        @error = 'Invalid two-factor code'
        render :two_factor and return
      end
    else
      if @user && @user.valid_password?(params[:user][:password])
        self.resource = @user

        if resource.otp_required_for_login
          render :two_factor and return
        end
      end
    end
  end
end

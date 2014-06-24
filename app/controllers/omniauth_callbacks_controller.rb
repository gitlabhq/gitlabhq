class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  Gitlab.config.omniauth.providers.each do |provider|
    define_method provider['name'] do
      handle_omniauth
    end
  end

  # Extend the standard message generation to accept our custom exception
  def failure_message
    exception = env["omniauth.error"]
    error   = exception.error_reason if exception.respond_to?(:error_reason)
    error ||= exception.error        if exception.respond_to?(:error)
    error ||= exception.message      if exception.respond_to?(:message)
    error ||= env["omniauth.error.type"].to_s
    error.to_s.humanize if error
  end

  def ldap
    # We only find ourselves here
    # if the authentication to LDAP was successful.
    @user = Gitlab::LDAP::User.find_or_create(oauth)
    @user.remember_me = true if @user.persisted?

    gitlab_ldap_access do |access|
      if access.allowed?(@user)
        sign_in_and_redirect(@user)
      else
        flash[:alert] = "Access denied for your LDAP account."
        redirect_to new_user_session_path
      end
    end
  end

  def omniauth_error
    @provider = params[:provider]
    @error = params[:error]
    render 'errors/omniauth_error', layout: "errors", status: 422
  end

  private

  def handle_omniauth
    if current_user
      # Change a logged-in user's authentication method:
      current_user.extern_uid = oauth['uid']
      current_user.provider = oauth['provider']
      current_user.save
      redirect_to profile_path
    else
      @user = Gitlab::OAuth::User.find(oauth)

      # Create user if does not exist
      # and allow_single_sign_on is true
      if Gitlab.config.omniauth['allow_single_sign_on'] && !@user
        @user, errors = Gitlab::OAuth::User.create(oauth)
      end

      if @user && !errors
        sign_in_and_redirect(@user)
      else
        if errors
          error_message = errors.map{ |attribute, message| "#{attribute} #{message}" }.join(", ")
          redirect_to omniauth_error_path(oauth['provider'], error: error_message) and return
        else
          flash[:notice] = "There's no such user!"
        end
        redirect_to new_user_session_path
      end
    end
  end

  def oauth
    @oauth ||= request.env['omniauth.auth']
  end
end

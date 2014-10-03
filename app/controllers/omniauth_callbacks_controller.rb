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

  # We only find ourselves here
  # if the authentication to LDAP was successful.
  def ldap
    @user = Gitlab::LDAP::User.new(oauth)
    @user.save if @user.changed? # will also save new users
    gl_user = @user.gl_user
    gl_user.remember_me = true if @user.persisted?

    # Do additional LDAP checks for the user filter and EE features
    if Gitlab::LDAP::Access.allowed?(gl_user)
      sign_in_and_redirect(gl_user)
    else
      flash[:alert] = "Access denied for your LDAP account."
      redirect_to new_user_session_path
    end
  end

  Gitlab.config.ldap.servers.each do |server|
    alias_method server.provider_name, :ldap
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
      @user = Gitlab::OAuth::User.new(oauth)

      if Gitlab.config.omniauth['allow_single_sign_on'] && @user.new?
        @user.save
      end

      if @user.valid?
        sign_in_and_redirect(@user.gl_user)
      else
        error_message = @user.gl_user.errors.map{ |attribute, message| "#{attribute} #{message}" }.join(", ")
        redirect_to omniauth_error_path(oauth['provider'], error: error_message) and return
      end
    end
  end

  def oauth
    @oauth ||= request.env['omniauth.auth']
  end
end

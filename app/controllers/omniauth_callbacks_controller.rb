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
    if @user.allowed?
      sign_in_and_redirect(gl_user)
    else
      flash[:alert] = "Access denied for your LDAP account."
      redirect_to new_user_session_path
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
      # Add new authentication method
      current_user.identities.find_or_create_by(extern_uid: oauth['uid'], provider: oauth['provider'])
      redirect_to profile_path
    else
      @user = Gitlab::OAuth::User.new(oauth)
      @user.save

      # Only allow properly saved users to login.
      if @user.persisted? && @user.valid?
        sign_in_and_redirect(@user.gl_user)
      else
        error_message =
          if @user.gl_user.errors.any?
            @user.gl_user.errors.map do |attribute, message|
              "#{attribute} #{message}"
            end.join(", ")
          else
            ''
          end

        redirect_to omniauth_error_path(oauth['provider'], error: error_message) and return
      end
    end
  rescue ForbiddenAction => e
    flash[:notice] = e.message
    redirect_to new_user_session_path
  end

  def oauth
    @oauth ||= request.env['omniauth.auth']
  end
end

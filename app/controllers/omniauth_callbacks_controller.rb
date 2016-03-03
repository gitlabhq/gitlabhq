class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AuthenticatesWithTwoFactor

  protect_from_forgery except: [:kerberos, :saml, :cas3]

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
    ldap_user = Gitlab::LDAP::User.new(oauth)
    ldap_user.save if ldap_user.changed? # will also save new users

    @user = ldap_user.gl_user
    @user.remember_me = params[:remember_me] if ldap_user.persisted?

    # Do additional LDAP checks for the user filter and EE features
    if ldap_user.allowed?
      if @user.two_factor_enabled?
        prompt_for_two_factor(@user)
      else
        log_audit_event(@user, with: :ldap)
        sign_in_and_redirect(@user)
      end
    else
      flash[:alert] = "Access denied for your LDAP account."
      redirect_to new_user_session_path
    end
  end

  def saml
    if current_user
      log_audit_event(current_user, with: :saml)
      # Update SAML identity if data has changed.
      identity = current_user.identities.find_by(extern_uid: oauth['uid'], provider: :saml)
      if identity.nil?
        current_user.identities.create(extern_uid: oauth['uid'], provider: :saml)
        redirect_to profile_account_path, notice: 'Authentication method updated'
      else
        redirect_to after_sign_in_path_for(current_user)
      end
    else
      saml_user = Gitlab::Saml::User.new(oauth)
      saml_user.save
      @user = saml_user.gl_user

      continue_login_process
    end
  end

  def omniauth_error
    @provider = params[:provider]
    @error = params[:error]
    render 'errors/omniauth_error', layout: "errors", status: 422
  end

  def cas3
    ticket = params['ticket']
    if ticket
      handle_service_ticket oauth['provider'], ticket
    end
    handle_omniauth
  end

  private

  def handle_omniauth
    if current_user
      # Add new authentication method
      current_user.identities.find_or_create_by(extern_uid: oauth['uid'], provider: oauth['provider'])
      log_audit_event(current_user, with: oauth['provider'])
      redirect_to profile_account_path, notice: 'Authentication method updated'
    else
      oauth_user = Gitlab::OAuth::User.new(oauth)
      oauth_user.save
      @user = oauth_user.gl_user

      continue_login_process
    end
  rescue Gitlab::OAuth::SignupDisabledError
    label = Gitlab::OAuth::Provider.label_for(oauth['provider'])
    message = "Signing in using your #{label} account without a pre-existing GitLab account is not allowed."

    if current_application_settings.signup_enabled?
      message << " Create a GitLab account first, and then connect it to your #{label} account."
    end

    flash[:notice] = message

    redirect_to new_user_session_path
  end

  def handle_service_ticket provider, ticket
    Gitlab::OAuth::Session.create provider, ticket
    session[:service_tickets] ||= {}
    session[:service_tickets][provider] = ticket
  end

  def continue_login_process
    # Only allow properly saved users to login.
    if @user.persisted? && @user.valid?
      log_audit_event(@user, with: oauth['provider'])
      sign_in_and_redirect(@user)
    else
      error_message = @user.errors.full_messages.to_sentence

      redirect_to omniauth_error_path(oauth['provider'], error: error_message) and return
    end
  end

  def oauth
    @oauth ||= request.env['omniauth.auth']
  end

  def log_audit_event(user, options = {})
    AuditEventService.new(user, user, options).
      for_authentication.security_event
  end
end

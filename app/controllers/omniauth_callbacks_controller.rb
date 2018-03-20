class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AuthenticatesWithTwoFactor
  include Devise::Controllers::Rememberable

  protect_from_forgery except: [:kerberos, :saml, :cas3]

  Gitlab.config.omniauth.providers.each do |provider|
    define_method provider['name'] do
      handle_omniauth
    end
  end

  if Gitlab::Auth::LDAP::Config.enabled?
    Gitlab::Auth::LDAP::Config.available_servers.each do |server|
      define_method server['provider_name'] do
        ldap
      end
    end
  end

  # Extend the standard implementation to also increment
  # the number of failed sign in attempts
  def failure
    user = User.find_by_username(params[:username])

    user&.increment_failed_attempts!

    super
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
    ldap_user = Gitlab::Auth::LDAP::User.new(oauth)
    ldap_user.save if ldap_user.changed? # will also save new users

    @user = ldap_user.gl_user
    @user.remember_me = params[:remember_me] if ldap_user.persisted?

    # Do additional LDAP checks for the user filter and EE features
    if ldap_user.allowed?
      if @user.two_factor_enabled?
        prompt_for_two_factor(@user)
      else
        log_audit_event(@user, with: oauth['provider'])
        sign_in_and_redirect(@user)
      end
    else
      fail_ldap_login
    end
  end

  def saml
    if current_user
      log_audit_event(current_user, with: :saml)
      # Update SAML identity if data has changed.
      identity = current_user.identities.with_extern_uid(:saml, oauth['uid']).take
      if identity.nil?
        current_user.identities.create(extern_uid: oauth['uid'], provider: :saml)
        redirect_to profile_account_path, notice: 'Authentication method updated'
      else
        redirect_to after_sign_in_path_for(current_user)
      end
    else
      saml_user = Gitlab::Auth::Saml::User.new(oauth)
      saml_user.save if saml_user.changed?
      @user = saml_user.gl_user

      continue_login_process
    end
  rescue Gitlab::Auth::OAuth::User::SignupDisabledError
    handle_signup_error
  end

  def omniauth_error
    @provider = params[:provider]
    @error = params[:error]
    render 'errors/omniauth_error', layout: "oauth_error", status: 422
  end

  def cas3
    ticket = params['ticket']
    if ticket
      handle_service_ticket oauth['provider'], ticket
    end

    handle_omniauth
  end

  def authentiq
    if params['sid']
      handle_service_ticket oauth['provider'], params['sid']
    end

    handle_omniauth
  end

  def auth0
    if oauth['uid'].blank?
      fail_auth0_login
    else
      handle_omniauth
    end
  end

  private

  def handle_omniauth
    if current_user
      # Add new authentication method
      current_user.identities
                  .with_extern_uid(oauth['provider'], oauth['uid'])
                  .first_or_create(extern_uid: oauth['uid'])
      log_audit_event(current_user, with: oauth['provider'])
      redirect_to profile_account_path, notice: 'Authentication method updated'
    else
      oauth_user = Gitlab::Auth::OAuth::User.new(oauth)
      oauth_user.save
      @user = oauth_user.gl_user

      continue_login_process
    end
  rescue Gitlab::Auth::OAuth::User::SigninDisabledForProviderError
    handle_disabled_provider
  rescue Gitlab::Auth::OAuth::User::SignupDisabledError
    handle_signup_error
  end

  def handle_service_ticket(provider, ticket)
    Gitlab::Auth::OAuth::Session.create provider, ticket
    session[:service_tickets] ||= {}
    session[:service_tickets][provider] = ticket
  end

  def continue_login_process
    # Only allow properly saved users to login.
    if @user.persisted? && @user.valid?
      log_audit_event(@user, with: oauth['provider'])

      if @user.two_factor_enabled?
        params[:remember_me] = '1' if remember_me?
        prompt_for_two_factor(@user)
      else
        remember_me(@user) if remember_me?
        sign_in_and_redirect(@user)
      end
    else
      fail_login
    end
  end

  def handle_signup_error
    label = Gitlab::Auth::OAuth::Provider.label_for(oauth['provider'])
    message = "Signing in using your #{label} account without a pre-existing GitLab account is not allowed."

    if Gitlab::CurrentSettings.allow_signup?
      message << " Create a GitLab account first, and then connect it to your #{label} account."
    end

    flash[:notice] = message

    redirect_to new_user_session_path
  end

  def oauth
    @oauth ||= request.env['omniauth.auth']
  end

  def fail_login
    error_message = @user.errors.full_messages.to_sentence

    return redirect_to omniauth_error_path(oauth['provider'], error: error_message)
  end

  def fail_ldap_login
    flash[:alert] = 'Access denied for your LDAP account.'

    redirect_to new_user_session_path
  end

  def fail_auth0_login
    flash[:alert] = 'Wrong extern UID provided. Make sure Auth0 is configured correctly.'

    redirect_to new_user_session_path
  end

  def handle_disabled_provider
    label = Gitlab::Auth::OAuth::Provider.label_for(oauth['provider'])
    flash[:alert] = "Signing in using #{label} has been disabled"

    redirect_to new_user_session_path
  end

  def log_audit_event(user, options = {})
    AuditEventService.new(user, user, options)
      .for_authentication.security_event
  end

  def remember_me?
    request_params = request.env['omniauth.params']
    (request_params['remember_me'] == '1') if request_params.present?
  end
end

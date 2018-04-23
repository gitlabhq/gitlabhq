class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AuthenticatesWithTwoFactor
  include Devise::Controllers::Rememberable

  protect_from_forgery except: [:kerberos, :saml, :cas3]

  Gitlab.config.omniauth.providers.each do |provider|
    define_method provider['name'] do
      handle_omniauth
    end
  end

  # Extend the standard implementation to also increment
  # the number of failed sign in attempts
  def failure
    if params[:username].present? && AuthHelper.form_based_provider?(failed_strategy.name)
      user = User.by_login(params[:username])

      user&.increment_failed_attempts!
    end

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

  def saml
    omniauth_flow(Gitlab::Auth::Saml)
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
    omniauth_flow(Gitlab::Auth::OAuth)
  end

  def omniauth_flow(auth_module, identity_linker: nil)
    if current_user
      log_audit_event(current_user, with: oauth['provider'])

      identity_linker ||= auth_module::IdentityLinker.new(current_user, oauth)

      identity_linker.link

      if identity_linker.changed?
        redirect_identity_linked
      elsif identity_linker.error_message.present?
        redirect_identity_link_failed(identity_linker.error_message)
      else
        redirect_identity_exists
      end
    else
      sign_in_user_flow(auth_module::User)
    end
  end

  def redirect_identity_exists
    redirect_to after_sign_in_path_for(current_user)
  end

  def redirect_identity_link_failed(error_message)
    redirect_to profile_account_path, notice: "Authentication failed: #{error_message}"
  end

  def redirect_identity_linked
    redirect_to profile_account_path, notice: 'Authentication method updated'
  end

  def handle_service_ticket(provider, ticket)
    Gitlab::Auth::OAuth::Session.create provider, ticket
    session[:service_tickets] ||= {}
    session[:service_tickets][provider] = ticket
  end

  def sign_in_user_flow(auth_user_class)
    auth_user = auth_user_class.new(oauth)
    user = auth_user.find_and_update!

    if auth_user.valid_sign_in?
      log_audit_event(user, with: oauth['provider'])

      set_remember_me(user)

      if user.two_factor_enabled?
        prompt_for_two_factor(user)
      else
        sign_in_and_redirect(user)
      end
    else
      fail_login(user)
    end
  rescue Gitlab::Auth::OAuth::User::SigninDisabledForProviderError
    handle_disabled_provider
  rescue Gitlab::Auth::OAuth::User::SignupDisabledError
    handle_signup_error
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

  def fail_login(user)
    error_message = user.errors.full_messages.to_sentence

    return redirect_to omniauth_error_path(oauth['provider'], error: error_message)
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

  def set_remember_me(user)
    return unless remember_me?

    if user.two_factor_enabled?
      params[:remember_me] = '1'
    else
      remember_me(user)
    end
  end

  def remember_me?
    request_params = request.env['omniauth.params']
    (request_params['remember_me'] == '1') if request_params.present?
  end
end

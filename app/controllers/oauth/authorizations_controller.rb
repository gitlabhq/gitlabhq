# frozen_string_literal: true

class Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  include Gitlab::GonHelper
  include InitializesCurrentUserMode
  include Gitlab::Utils::StrongMemoize

  before_action :add_gon_variables
  before_action :verify_confirmed_email!, :verify_admin_allowed!

  layout 'profile'

  # Overridden from Doorkeeper::AuthorizationsController to
  # include the call to session.delete
  def new
    if pre_auth.authorizable?
      if skip_authorization? || (matching_token? && pre_auth.client.application.confidential?)
        auth = authorization.authorize
        parsed_redirect_uri = URI.parse(auth.redirect_uri)
        session.delete(:user_return_to)
        render "doorkeeper/authorizations/redirect", locals: { redirect_uri: parsed_redirect_uri }, layout: false
      else
        redirect_uri = URI(authorization.authorize.redirect_uri)
        allow_redirect_uri_form_action(redirect_uri.scheme)

        render "doorkeeper/authorizations/new"
      end
    else
      render "doorkeeper/authorizations/error"
    end
  end

  private

  # Chrome blocks redirections if the form-action CSP directive is present
  # and the redirect location's scheme isn't allow-listed
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/form-action
  # https://github.com/w3c/webappsec-csp/issues/8
  def allow_redirect_uri_form_action(redirect_uri_scheme)
    return unless content_security_policy?

    form_action = request.content_security_policy.form_action
    return unless form_action

    form_action.push("#{redirect_uri_scheme}:")
    request.content_security_policy.form_action(*form_action)
  end

  def pre_auth_params
    # Cannot be achieved with a before_action hook, due to the execution order.
    downgrade_scopes! if action_name == 'new'

    super
  end

  # limit scopes when signing in with GitLab
  def downgrade_scopes!
    auth_type = params.delete('gl_auth_type')
    return unless auth_type == 'login'

    ensure_read_user_scope!

    params['scope'] = Gitlab::Auth::READ_USER_SCOPE.to_s if application_has_read_user_scope?
  end

  # Configure the application to support read_user scope, if it already
  # supports scopes with greater levels of privileges.
  def ensure_read_user_scope!
    return if application_has_read_user_scope?
    return unless application_has_api_scope?

    add_read_user_scope!
  end

  def add_read_user_scope!
    return unless doorkeeper_application

    scopes = doorkeeper_application.scopes
    scopes.add(Gitlab::Auth::READ_USER_SCOPE)
    doorkeeper_application.scopes = scopes
    doorkeeper_application.save!
  end

  def doorkeeper_application
    strong_memoize(:doorkeeper_application) { ::Doorkeeper::OAuth::Client.find(params['client_id'])&.application }
  end

  def application_has_read_user_scope?
    doorkeeper_application&.includes_scope?(Gitlab::Auth::READ_USER_SCOPE)
  end

  def application_has_api_scope?
    doorkeeper_application&.includes_scope?(*::Gitlab::Auth::API_SCOPES)
  end

  def verify_confirmed_email!
    return if current_user&.confirmed?

    pre_auth.error = :unconfirmed_email
    render "doorkeeper/authorizations/error"
  end

  def verify_admin_allowed!
    render "doorkeeper/authorizations/forbidden" if disallow_connect?
  end

  def disallow_connect?
    # we're disabling Cop/UserAdmin as OAuth tokens don't seem to respect admin mode
    current_user&.admin? && Gitlab::CurrentSettings.disable_admin_oauth_scopes && dangerous_scopes? # rubocop:disable Cop/UserAdmin
  end

  def dangerous_scopes?
    doorkeeper_application&.includes_scope?(
      *::Gitlab::Auth::API_SCOPE, *::Gitlab::Auth::READ_API_SCOPE,
      *::Gitlab::Auth::ADMIN_SCOPES, *::Gitlab::Auth::REPOSITORY_SCOPES,
      *::Gitlab::Auth::REGISTRY_SCOPES
    ) && !doorkeeper_application&.trusted?
  end
end

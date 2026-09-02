# frozen_string_literal: true

class Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  include Gitlab::GonHelper
  include InitializesCurrentUserMode
  include Gitlab::Utils::StrongMemoize
  include RequestPayloadLogger

  # Marker appended to a dynamically-registered (DCR) application's name to
  # record which user authorized it. DCR registration is anonymous, so the
  # authorizing user is the earliest point at which we know who is behind the app.
  DYNAMIC_APP_AUTHORIZED_BY = ' — authorized by @'

  prepend_before_action :set_current_organization

  before_action :add_gon_variables
  before_action :verify_confirmed_email!, :verify_admin_allowed!
  # rubocop: disable Rails/LexicallyScopedActionFilter -- :create is defined in Doorkeeper::AuthorizationsController
  before_action :validate_pkce_for_dynamic_applications, only: [:new, :create]
  before_action :explain_missing_dynamic_client, only: [:new, :create]
  after_action :audit_oauth_authorization, only: [:create]
  after_action :stamp_authorizing_user_on_dynamic_application, only: [:create]
  # rubocop: enable Rails/LexicallyScopedActionFilter

  layout 'minimal'

  # Overridden from Doorkeeper::AuthorizationsController to
  # include the call to session.delete
  def new
    if pre_auth.authorizable?
      if skip_authorization? || (matching_token? && pre_auth.client.application.confidential?)
        auth = authorize_with_sanctioned_write
        parsed_redirect_uri = URI.parse(auth.redirect_uri)
        session.delete(:user_return_to)
        render "doorkeeper/authorizations/redirect", locals: { redirect_uri: parsed_redirect_uri }, layout: false
      else
        redirect_uri = URI(authorize_with_sanctioned_write.redirect_uri)
        allow_redirect_uri_form_action(redirect_uri.scheme)

        render "doorkeeper/authorizations/new"
      end
    else
      render "doorkeeper/authorizations/error"
    end
  end

  private

  def authorize_with_sanctioned_write
    Gitlab::Database::QueryAnalyzers::PreventWritesOnGet.allow_write_on_get(
      url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/608670'
    ) { authorization.authorize }
  end

  def permitted_params
    params.permit(:resource, :client_id, :code_challenge, :code_challenge_method)
  end
  strong_memoize_attr :permitted_params

  # In Rails 8 alias_method at class-body level fails when the aliased method
  # is not yet in the ancestor chain at load time. Define explicitly instead.
  def auth_user
    current_user
  end

  def audit_oauth_authorization
    return unless performed? && (response.successful? || response.redirect?) && pre_auth&.client

    application = pre_auth.client.application

    Gitlab::Audit::Auditor.audit(
      name: 'user_authorized_oauth_application',
      author: current_user,
      scope: current_user,
      target: application,
      message: 'User authorized an OAuth application.',
      additional_details: {
        application_name: application.name,
        application_id: application.id,
        scopes: application.scopes.to_a
      },
      ip_address: request.remote_ip
    )
  end

  # DCR (dynamic client registration) happens without an authenticated user, so
  # the application name can only identify the client, not who is using it. Once
  # a user authorizes the app we stamp their username onto the name (once), so
  # admins can tell which user is behind an otherwise-anonymous dynamic app.
  #
  # We stamp only on a genuine approval. Doorkeeper's `authorize_response` is a
  # CodeResponse once an authorization code has been issued; a denial or error
  # yields an ErrorResponse, so those are left untouched and we never
  # misattribute an authorization the user did not grant.
  def stamp_authorizing_user_on_dynamic_application
    return if skip_dynamic_application_name_stamp?
    return unless performed? && authorize_response.is_a?(Doorkeeper::OAuth::CodeResponse)
    return unless current_user

    application = pre_auth&.client&.application
    return unless application&.dynamic?
    return if application.name.include?(DYNAMIC_APP_AUTHORIZED_BY)

    application.update(name: "#{application.name}#{DYNAMIC_APP_AUTHORIZED_BY}#{sanitized_authorizing_username}")
  end

  # Overridden in EE to skip stamping on GitLab.com, where MCP clients reuse a
  # single dynamic OAuth application across users, making a per-user stamp
  # misleading. Self-managed instances still stamp.
  def skip_dynamic_application_name_stamp?
    false
  end

  # GitLab usernames are already restricted to a safe character set, but we
  # defensively strip anything outside it before persisting the value into the
  # application name, which is later rendered in the admin UI.
  def sanitized_authorizing_username
    current_user.username.gsub(/[^A-Za-z0-9_.-]/, '')
  end

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

    # Force the appropriate MCP scope for MCP server requests and dynamic MCP applications.
    # This ensures that even if a client requests other scopes, dynamic MCP applications
    # are restricted to the correct scope only, regardless of what was requested.
    # rubocop:disable Rails/StrongParams -- In-place writes to params consumed by Doorkeeper's pre_auth via super
    if resource_is_mcp_orbit_server? || should_force_scope_for_dynamic_app?(Gitlab::Auth::MCP_ORBIT_SCOPE)
      params[:scope] = Gitlab::Auth::MCP_ORBIT_SCOPE.to_s
    elsif resource_is_mcp_server? || should_force_scope_for_dynamic_app?(Gitlab::Auth::MCP_SCOPE)
      params[:scope] = Gitlab::Auth::MCP_SCOPE.to_s
    end

    params[:organization_id] = ::Current.organization.id
    # rubocop:enable Rails/StrongParams

    super
  end

  def resource_is_mcp_server?
    resource = permitted_params[:resource]
    resource.present? && resource.end_with?('/api/v4/mcp')
  end

  def resource_is_mcp_orbit_server?
    resource = permitted_params[:resource]
    resource.present? && resource.end_with?('/api/v4/orbit/mcp')
  end

  def should_force_scope_for_dynamic_app?(scope)
    doorkeeper_application&.dynamic? &&
      doorkeeper_application&.scopes == Doorkeeper::OAuth::Scopes.from_string(scope.to_s)
  end

  # limit scopes when signing in with GitLab
  def downgrade_scopes!
    # rubocop:disable Rails/StrongParams -- In-place writes to params consumed by Doorkeeper's pre_auth via super
    auth_type = params.delete('gl_auth_type')
    return unless auth_type == 'login'

    ensure_read_user_scope!

    params['scope'] = Gitlab::Auth::READ_USER_SCOPE.to_s if application_has_read_user_scope?
    # rubocop:enable Rails/StrongParams
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
    ::Doorkeeper::OAuth::Client.find(permitted_params[:client_id].to_s)&.application
  end
  strong_memoize_attr :doorkeeper_application

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

  def explain_missing_dynamic_client
    return if ::Gitlab::CurrentSettings.dynamic_client_registration_enabled?
    return if params.permit(:client_id)[:client_id].blank?
    return if doorkeeper_application.present?

    render "doorkeeper/authorizations/error", locals: {
      error_description_override:
        _("The OAuth client is not recognized. When dynamic client registration is " \
          "disabled, clients registered that way are removed and new ones cannot " \
          "register. Create an OAuth application and configure your MCP client with its " \
          "client ID:"),
      error_description_docs_url: help_page_url(
        'user/model_context_protocol/mcp_server.md',
        anchor: 'reuse-a-single-oauth-application'
      )
    }
  end

  def validate_pkce_for_dynamic_applications
    return unless doorkeeper_application&.dynamic?

    if permitted_params[:code_challenge].blank?
      pre_auth.error = :pkce_required_for_dynamic_applications
      render "doorkeeper/authorizations/error"
      return
    end

    code_challenge_method = permitted_params[:code_challenge_method]
    return unless code_challenge_method.present? && code_challenge_method != 'S256'

    pre_auth.error = :invalid_code_challenge_method
    render "doorkeeper/authorizations/error"
  end

  # Used by `set_current_organization` in BaseActionController
  def organization_params
    {}
  end
end

Oauth::AuthorizationsController.prepend_mod

# frozen_string_literal: true

class Oauth::TokensController < Doorkeeper::TokensController
  include EnforcesTwoFactorAuthentication
  include RequestPayloadLogger
  include Gitlab::InternalEventsTracking

  # RFC 7636 Section 4.1 requires PKCE code verifiers to be at least 43 characters.
  # Track requests that use shorter verifiers to measure how many clients are non-compliant
  # before enforcing the minimum.
  PKCE_MIN_CODE_VERIFIER_LENGTH = 43

  before_action :explain_missing_dynamic_client, only: [:create]
  before_action :validate_pkce_for_dynamic_applications, only: [:create]
  before_action :track_short_pkce_verifier, only: [:create]
  before_action :enforce_organization_maintenance_mode, only: [:create]

  def create
    if authorize_response.status == :ok
      track_internal_event(
        'oauth_authorize_with_gitlab',
        user: authorize_response.token.resource_owner,
        additional_properties: {
          label: server.client.present?.to_s,
          property: params[:grant_type] # rubocop:disable Rails/StrongParams -- This pattern is followed in the gem
        }
      )
    end

    super
  end

  private

  def enforce_organization_maintenance_mode
    organization = organization_for_token_request
    return unless organization&.under_maintenance?

    render_organization_maintenance_mode_error(organization)
  end

  def organization_for_token_request
    token_params = params.permit(:grant_type, :refresh_token, :code)

    case token_params[:grant_type]
    when 'refresh_token'
      OauthAccessToken.by_refresh_token(token_params[:refresh_token])&.organization
    when 'authorization_code'
      OauthAccessGrant.by_token(token_params[:code])&.organization
    end
  end

  def render_organization_maintenance_mode_error(organization)
    if organization.maintenance_time_bounded?
      response.headers['Retry-After'] =
        ::Organizations::Organization::MAINTENANCE_MODE_RETRY_AFTER_SECONDS.to_s
      status = :service_unavailable
      error = 'temporarily_unavailable'
    else
      status = :forbidden
      error = 'access_denied'
    end

    render json: {
      error: error,
      error_description: organization.maintenance_message
    }, status: status
  end

  # In Rails 8 alias_method at class-body level fails when the aliased method
  # is not yet in the ancestor chain at load time. Define explicitly instead.
  def auth_user
    current_user
  end

  def append_info_to_payload(payload)
    super

    if @authorize_response.respond_to?(:token) && @authorize_response.token.is_a?(Doorkeeper::AccessToken)
      payload[:metadata] ||= {}
      payload[:metadata][:oauth_access_token_id] = @authorize_response.token.id
      payload[:metadata][:oauth_access_token_application_id] = @authorize_response.token.application_id
      payload[:metadata][:oauth_access_token_scopes] = @authorize_response.token.scopes_string
    end

    # rubocop:disable Rails/StrongParams -- following existing param access pattern
    if params[:grant_type] == 'refresh_token' && params[:refresh_token].present?
      payload[:metadata] ||= {}
      payload[:metadata][:refresh_token_hash] = Digest::SHA256.hexdigest(params[:refresh_token])[0..9]
    end
    # rubocop:enable Rails/StrongParams

    payload
  end

  def explain_missing_dynamic_client
    return if ::Gitlab::CurrentSettings.dynamic_client_registration_enabled?

    client_id = params.permit(:client_id)[:client_id]
    return if client_id.blank?
    return if Authn::OauthApplication.exists_for_uid?(client_id)

    docs_url = help_page_url(
      'user/model_context_protocol/mcp_server.md',
      anchor: 'reuse-a-single-oauth-application'
    )

    render json: {
      error: 'invalid_client',
      error_description: 'The OAuth client is not recognized. When dynamic client ' \
        'registration is disabled, clients registered that way are removed and new ones ' \
        'cannot register. Create an OAuth application and configure your MCP client with ' \
        "its client ID: #{docs_url}"
    }, status: :unauthorized
  end

  def validate_pkce_for_dynamic_applications
    return unless server.client&.application&.dynamic?
    # PKCE validation only applies to authorization_code grants per RFC 7636 Section 4.5.
    return unless params[:grant_type] == 'authorization_code' # rubocop:disable Rails/StrongParams -- Only accessing a single named param
    return unless params[:code_verifier].blank? # rubocop:disable Rails/StrongParams -- Only accessing a single named param

    render json: {
      error: 'invalid_request',
      error_description: 'PKCE code_verifier is required for dynamic OAuth applications'
    }, status: :bad_request
  end

  def track_short_pkce_verifier
    return unless params[:grant_type] == 'authorization_code' # rubocop:disable Rails/StrongParams -- Only accessing a single named param

    verifier = params[:code_verifier] # rubocop:disable Rails/StrongParams -- Only accessing a single named param
    return if verifier.blank? || verifier.length >= PKCE_MIN_CODE_VERIFIER_LENGTH

    track_internal_event(
      'oauth_authorize_with_short_pkce_verifier',
      user: current_user,
      additional_properties: {
        label: server.client&.uid.to_s
      }
    )
  end
end

# frozen_string_literal: true

class JwksController < Doorkeeper::OpenidConnect::DiscoveryController
  include ::Gitlab::EndpointAttributes

  feature_category :system_access

  DYNAMIC_REGISTRATION_PATH = '/oauth/register'

  OAUTH_PATHS = [
    '/.well-known/oauth-authorization-server',
    '/.well-known/oauth-authorization-server/api/v4/mcp',
    '/.well-known/openid-configuration/api/v4/mcp'
  ].freeze

  def keys
    expires_in 24.hours, public: true, must_revalidate: true, 'no-transform': true

    render json: { keys: payload }
  end

  def provider
    if request.path.in?(OAUTH_PATHS)
      expires_in 24.hours, public: true, must_revalidate: true, 'no-transform': true
      response_hash = provider_response
      response_hash[:registration_endpoint] = "#{request.base_url}#{DYNAMIC_REGISTRATION_PATH}"
      render json: response_hash

      return
    end

    super
  end

  private

  def payload
    load_keys.flatten.compact.uniq.map { |key_data| pem_to_jwk(key_data) }
  end

  # overridden in EE
  def load_keys
    [
      ::Rails.application.credentials.openid_connect_signing_key,
      ::Gitlab::CurrentSettings.ci_jwt_signing_key
    ]
  end

  def pem_to_jwk(key_data)
    OpenSSL::PKey::RSA.new(key_data)
        .public_key
        .to_jwk
        .slice(:kty, :kid, :e, :n)
        .merge(use: 'sig', alg: 'RS256')
  end

  def provider_response
    response = super
    response[:claims_supported] += %w[project_path ci_config_ref_uri ref_path sha environment jti]

    # Filter scopes for MCP-specific discovery endpoints
    response[:scopes_supported] = [Gitlab::Auth::MCP_SCOPE.to_s] if request.path.end_with?('/api/v4/mcp')

    response
  end
end

JwksController.prepend_mod

# frozen_string_literal: true

class JwksController < Doorkeeper::OpenidConnect::DiscoveryController
  def index
    if ::Feature.enabled?(:cache_control_headers_for_openid_jwks)
      expires_in 24.hours, public: true, must_revalidate: true, 'no-transform': true
    end

    render json: { keys: payload }
  end

  def keys
    index
  end

  private

  def payload
    [
      Rails.application.secrets.openid_connect_signing_key,
      Gitlab::CurrentSettings.ci_jwt_signing_key
    ].compact.map do |key_data|
      OpenSSL::PKey::RSA.new(key_data)
        .public_key
        .to_jwk
        .slice(:kty, :kid, :e, :n)
        .merge(use: 'sig', alg: 'RS256')
    end
  end
end

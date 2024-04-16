# frozen_string_literal: true

class JwksController < Doorkeeper::OpenidConnect::DiscoveryController
  # To be removed soon
  def index
    if Feature.enabled?(:remove_jwks_endpoint)
      render status: :not_found
    else
      keys
    end
  end

  def keys
    expires_in 24.hours, public: true, must_revalidate: true, 'no-transform': true

    render json: { keys: payload }
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

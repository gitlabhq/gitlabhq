# frozen_string_literal: true

class JwksController < Doorkeeper::OpenidConnect::DiscoveryController
  def keys
    expires_in 24.hours, public: true, must_revalidate: true, 'no-transform': true

    render json: { keys: payload }
  end

  private

  def payload
    [
      Rails.application.credentials.openid_connect_signing_key,
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

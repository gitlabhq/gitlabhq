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
      Gitlab::CurrentSettings.ci_jwt_signing_key,
      cloud_connector_keys
    ].flatten.compact.map { |key_data| pem_to_jwk(key_data) }.uniq
  end

  def cloud_connector_keys
    return unless Gitlab.ee?

    CloudConnector::Keys.all_as_pem
  end

  def pem_to_jwk(key_data)
    OpenSSL::PKey::RSA.new(key_data)
        .public_key
        .to_jwk
        .slice(:kty, :kid, :e, :n)
        .merge(use: 'sig', alg: 'RS256')
  end
end

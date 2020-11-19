# frozen_string_literal: true

class JwksController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def index
    render json: { keys: keys }
  end

  private

  def keys
    [
      # We keep openid_connect_signing_key so that we can seamlessly
      # replace it with ci_jwt_signing_key and remove it on the next release.
      # TODO: Remove openid_connect_signing_key in 13.7
      # https://gitlab.com/gitlab-org/gitlab/-/issues/221031
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

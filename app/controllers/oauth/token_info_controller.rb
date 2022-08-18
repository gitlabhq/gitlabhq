# frozen_string_literal: true

class Oauth::TokenInfoController < Doorkeeper::TokenInfoController
  include EnforcesTwoFactorAuthentication

  def show
    if doorkeeper_token && doorkeeper_token.accessible?
      token_json = doorkeeper_token.as_json

      # maintain backwards compatibility
      render json: token_json.merge(
        'scopes' => token_json[:scope],
        'expires_in_seconds' => token_json[:expires_in]
      ), status: :ok
    else
      error = Doorkeeper::OAuth::InvalidTokenResponse.new
      response.headers.merge!(error.headers)
      render json: error.body, status: error.status
    end
  end
end

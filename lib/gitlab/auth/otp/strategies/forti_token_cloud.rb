# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      module Strategies
        class FortiTokenCloud < Base
          include Gitlab::Utils::StrongMemoize
          BASE_API_URL = 'https://ftc.fortinet.com:9696/api/v1'

          def validate(otp_code)
            if access_token_create_response.created?
              otp_verification_response = verify_otp(otp_code)

              otp_verification_response.ok? ? success : error_from_response(otp_verification_response)
            else
              error_from_response(access_token_create_response)
            end
          end

          private

          # TODO: Cache the access token: https://gitlab.com/gitlab-org/gitlab/-/issues/292437
          def access_token_create_response
            # Returns '201 CREATED' on successful creation of a new access token.
            strong_memoize(:access_token_create_response) do
              post(
                url: url('/login'),
                body: {
                        client_id: ::Gitlab.config.forti_token_cloud.client_id,
                        client_secret: ::Gitlab.config.forti_token_cloud.client_secret
                }.to_json
              )
            end
          end

          def access_token
            Gitlab::Json.parse(access_token_create_response.body)['access_token']
          end

          def verify_otp(otp_code)
            # Returns '200 OK' on successful verification.
            # Uses the access token created via `access_token_create_response` as the auth token.
            post(
              url: url('/auth'),
              headers: { Authorization: "Bearer #{access_token}" },
              body: {
                      username: user.username,
                      token: otp_code
              }.to_json
            )
          end

          def url(path)
            BASE_API_URL + path
          end

          def post(url:, body:, headers: {})
            Gitlab::HTTP.post(
              url,
              headers: {
                'Content-Type': 'application/json'
              }.merge(headers),
              body: body
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module OrgMover
    # Verifies requests from the org-mover control plane to the internal Org Mover API.
    # Cells hold only public keys, so a compromised cell cannot mint tokens for another cell,
    # and the audience names the target cell, so it cannot replay tokens sent to it elsewhere.
    class Authenticator
      include JwtAuthenticatable

      API_HEADER = 'Gitlab-Org-Mover-Api-Request'
      JWT_ISSUER = 'gitlab-org-mover'
      JWT_AUDIENCE = 'gitlab-org-mover-api'
      EXPIRATION = 5.minutes
      CLOCK_SKEW = 30.seconds
      MAX_TOKEN_LENGTH = 2.kilobytes
      TOKEN_FORMAT = /\A[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\z/

      class << self
        include Gitlab::Utils::StrongMemoize

        def verify_api_request(headers)
          token = headers[API_HEADER]
          return if !well_formed?(token) || public_key_files.blank? || !Gitlab.config.cell.enabled

          decoded_token = decode_jwt(
            token,
            nil,
            algorithm: 'ES256',
            jwks: jwks,
            issuer: JWT_ISSUER,
            iat_after: Time.current - EXPIRATION,
            iat_leeway: CLOCK_SKEW
          )

          decoded_token if addressed_to_this_cell?(decoded_token.first)
        rescue JWT::DecodeError
          nil
        end

        private

        def well_formed?(token)
          token.is_a?(String) && token.bytesize <= MAX_TOKEN_LENGTH && TOKEN_FORMAT.match?(token)
        end

        # Exact match, not decode_jwt's audience check, which also accepts a list naming other cells.
        def addressed_to_this_cell?(payload)
          payload['aud'] == "#{JWT_AUDIENCE}:cell-#{Gitlab.config.cell.id}"
        end

        def jwks
          public_key_set(public_key_files, kid_generator: ::JWT::JWK::Thumbprint)
        end
        strong_memoize_attr :jwks

        def public_key_files
          Gitlab.config.org_mover.public_key_files
        end
      end
    end
  end
end

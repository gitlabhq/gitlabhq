# frozen_string_literal: true

# Demonstrated Proof of Possession (DPoP) is a mechanism to tie a user's
# Personal Access Token (PAT) to one of their signing keys.
#
# A DPoP Token is a signed JSON Web Token. This class implements
# the logic to ensure a provided DPoP Token is well-formed and
# cryptographically signed.
#
module Gitlab
  module Auth
    class DpopToken
      KID_DELIMITER = ':'

      attr_reader :data, :payload, :header

      def initialize(data:)
        @data = data
      end

      def validate!
        begin
          @payload, @header = JWT.decode(
            data,
            nil, # we do not pass a key here as we are not checking the signature
            false # we are not verifying the signature or claims
          )
        rescue JWT::DecodeError => e
          raise Gitlab::Auth::DpopValidationError, "Malformed JWT, unable to decode. #{e.message}"
        end

        # All comparisons should be case-sensitive, using secure comparison
        # See https://www.rfc-editor.org/rfc/rfc7515#section-4.1.1
        raise Gitlab::Auth::DpopValidationError, 'Invalid typ value in JWT' unless header['typ'].casecmp?('dpop+jwt')

        raise Gitlab::Auth::DpopValidationError, 'No kid in JWT, unable to fetch key' if header['kid'].nil?

        # Check header[alg] is one of SUPPORTED_JWS_ALGORITHMS.
        # Remove when support for ED25519 is added
        # This checks for 'alg' in the header and exits early
        unless header['alg'].casecmp?('RS512')
          raise Gitlab::Auth::DpopValidationError,
            'Currently only RSA keys are supported'
        end

        # Check the format of header[kid] (ALGORITHM DELIMITER b64(HASH))
        kid_parts = header['kid'].split(KID_DELIMITER)
        raise Gitlab::Auth::DpopValidationError, 'Malformed fingerprint value in kid' unless kid_parts.size == 2

        # Check kid_algorithm is supported
        kid_algorithm = kid_parts[0]
        unless kid_algorithm.casecmp?('SHA256')
          raise Gitlab::Auth::DpopValidationError, 'Unsupported fingerprint algorithm in kid'
        end

        return if header.dig('jwk', 'kty').eql?('RSA')

        raise Gitlab::Auth::DpopValidationError, 'JWK algorithm must be RSA'
      end
    end
  end
end

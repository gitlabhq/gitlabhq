# frozen_string_literal: true

module Doorkeeper # rubocop:disable Gitlab/BoundedContexts -- Override from a gem
  module Concerns
    module TokenFallback
      extend ActiveSupport::Concern

      class_methods do
        include Gitlab::Utils::StrongMemoize

        # Allow looking up previously plain tokens as a fallback
        # IFF a fallback strategy has been defined
        #
        # This method overrides the upstream Doorkeeper implementation to support
        # multiple fallback strategies instead of a single fallback_secret_strategy.
        #
        # @param attr [Symbol] The token attribute we're looking with
        # @param plain_secret [#to_s] Plain secret value (any object that responds to `#to_s`)
        # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil if there is no record with such token
        #
        # @example
        #   OauthAccessToken.find_by_fallback_token(:token, "my_plain_token")
        #   #=> #<OauthAccessToken:0x...> or nil
        #
        # @note This method skips lookup for already hashed tokens to avoid unnecessary processing:
        #   - PBKDF2 hashed tokens (format: $pbkdf2-sha512$20000$$.c0G5XJV...)
        #   - SHA512 hashed tokens (128 hexadecimal characters)
        #
        # @see #upgrade_fallback_value
        # @see .fallback_strategies
        def find_by_fallback_token(attr, plain_secret)
          return if plain_secret.start_with?('$pbkdf2-') || # PBKDF2 format
            (plain_secret.length == 128 && plain_secret.match?(/\A[a-f0-9]{128}\z/i)) # SHA512 format

          # Try each fallback strategy until we find a match
          fallback_strategies.each do |fallback_strategy|
            stored_token = fallback_strategy.transform_secret(plain_secret)

            resource = find_by(attr => stored_token)
            if resource
              upgrade_fallback_value(resource, attr, plain_secret)
              return resource
            end
          end
          nil
        end

        def fallback_strategies
          if Gitlab::FIPS.enabled? && fips_140_3?
            [Doorkeeper::SecretStoring::Plain]
          else
            [Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512,
              Doorkeeper::SecretStoring::Plain]
          end
        end

        # Check if FIPS implementation is FIPS 140-3 or above
        # This is a hacky solution to finf fips version as FIPS 140-3 mandates longer salt length
        # Refer https://docs.gitlab.com/development/fips_gitlab/ for more details
        def fips_140_3?
          OpenSSL::KDF.pbkdf2_hmac(
            'foo',
            salt: ['1234'].pack("H*"),
            iterations: 20000,
            hash: OpenSSL::Digest.new("SHA512"),
            length: 64
          ).unpack1('H*')
          false
        rescue OpenSSL::KDF::KDFError => _
          true
        end
        strong_memoize_attr :fips_140_3?
      end
    end
  end
end

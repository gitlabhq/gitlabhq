# frozen_string_literal:true

module Authn
  module Tokens
    class FeatureFlagsClientToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::Operations::FeatureFlagsClient::FEATURE_FLAGS_CLIENT_TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Operations::FeatureFlagsClient.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::FeatureFlags::ClientConfigurationEntity
      end

      def revoke!(_current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type'
      end
    end
  end
end

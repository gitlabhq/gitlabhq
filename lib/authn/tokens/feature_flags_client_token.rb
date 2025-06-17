# frozen_string_literal:true

module Authn
  module Tokens
    class FeatureFlagsClientToken
      def self.prefix?(plaintext)
        feature_flags_client_token_prefixes = [::Operations::FeatureFlagsClient.prefix_for_feature_flags_client_token,
          ::Operations::FeatureFlagsClient::FEATURE_FLAGS_CLIENT_TOKEN_PREFIX].uniq

        plaintext.start_with?(*feature_flags_client_token_prefixes)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Operations::FeatureFlagsClient.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::FeatureFlags::ClientConfigurationEntity
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        ::Environments::FeatureFlags::ResetClientTokenService.new(current_user: current_user,
          feature_flags_client: revocable).execute!
      end
    end
  end
end

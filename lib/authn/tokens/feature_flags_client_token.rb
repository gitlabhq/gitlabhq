# frozen_string_literal:true

module Authn
  module Tokens
    class FeatureFlagsClientToken
      def self.prefix?(plaintext)
        current_prefix = ::Operations::FeatureFlagsClient.prefix_for_feature_flags_client_token
        default_prefix = Authn::TokenField::PrefixHelper.default_instance_prefix(current_prefix)
        plaintext.start_with?(current_prefix, default_prefix)
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

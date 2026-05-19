# frozen_string_literal: true

module Ci
  module Runners
    class PartitionedTokenFinder < Authn::TokenField::Finders::BaseEncryptedPartitioned
      include Gitlab::Utils::StrongMemoize

      def execute
        return if irrelevant_token?

        super
      end

      protected

      def partition_key
        ::Ci::Runners::TokenPartition.new(token).decode
      end
      strong_memoize_attr :partition_key

      def partition_scope
        base_scope.with_runner_type(partition_key)
      end

      def skip_fallback?
        # Ci::Runner's token is partition scoped
        # Therefore, no need to fallback to all partitions for uniqueness_check
        options[:uniqueness_check]
      end

      def irrelevant_token?
        known_non_runner_token_types.any? { |type| type.prefix?(token) }
      end

      def known_non_runner_token_types
        ::Authn::AgnosticTokenIdentifier::TOKEN_TYPES - [::Authn::Tokens::RunnerAuthenticationToken]
      end
    end
  end
end

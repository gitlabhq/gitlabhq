# frozen_string_literal: true

module Ci
  module Jobs
    class PartitionedTokenFinder < Authn::TokenField::Finders::BaseEncryptedPartitioned
      include Gitlab::Utils::StrongMemoize

      def execute
        return if irrelevant_token?

        super
      end

      protected

      def partition_key
        ::Ci::Builds::TokenPrefix.decode_partition(token)
      end
      strong_memoize_attr :partition_key

      def partition_scope
        base_scope.in_partition(partition_key)
      end

      def skip_fallback?
        # Ci::Build's token is partition scoped
        # Therefore, no need to fallback to all partitions for uniqueness_check
        options[:uniqueness_check]
      end

      def irrelevant_token?
        invalid_job_token? || known_non_job_token?
      end

      def invalid_job_token?
        # NOTE: for JWT job token, it won't get here as this is for database-backed job tokens
        ::Authn::Tokens::CiJobToken.prefix?(token) && partition_key.blank?
      end

      def known_non_job_token?
        known_non_job_token_types.any? { |type| type.prefix?(token) }
      end

      def known_non_job_token_types
        ::Authn::AgnosticTokenIdentifier::TOKEN_TYPES - [::Authn::Tokens::CiJobToken]
      end
    end
  end
end

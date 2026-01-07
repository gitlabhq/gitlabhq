# frozen_string_literal: true

module Ci
  module Jobs
    class PartitionedTokenFinder < Authn::TokenField::Finders::BaseEncryptedPartitioned
      include Gitlab::Utils::StrongMemoize

      protected

      def partition_key
        ::Ci::Builds::TokenPrefix.decode_partition(token)
      end
      strong_memoize_attr :partition_key

      def partition_scope
        base_scope.in_partition(partition_key)
      end
    end
  end
end

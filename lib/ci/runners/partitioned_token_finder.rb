# frozen_string_literal: true

module Ci
  module Runners
    class PartitionedTokenFinder < Authn::TokenField::Finders::BaseEncryptedPartitioned
      include Gitlab::Utils::StrongMemoize

      protected

      def partition_key
        ::Ci::Runners::TokenPartition.new(token).decode
      end
      strong_memoize_attr :partition_key

      def partition_scope
        base_scope.with_runner_type(partition_key)
      end
    end
  end
end

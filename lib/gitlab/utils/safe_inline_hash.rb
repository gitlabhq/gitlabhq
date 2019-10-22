# frozen_string_literal: true

module Gitlab
  module Utils
    class SafeInlineHash
      # Validates the hash size using `Gitlab::Utils::DeepSize` before merging keys using `Gitlab::Utils::InlineHash`
      def initialize(hash, prefix: nil, connector: '.')
        @hash = hash
      end

      def self.merge_keys!(hash, prefix: nil, connector: '.')
        new(hash).merge_keys!(prefix: prefix, connector: connector)
      end

      def merge_keys!(prefix:, connector:)
        raise ArgumentError, 'The Hash is too big' unless valid?

        Gitlab::Utils::InlineHash.merge_keys(hash, prefix: prefix, connector: connector)
      end

      private

      attr_reader :hash

      def valid?
        Gitlab::Utils::DeepSize.new(hash).valid?
      end
    end
  end
end

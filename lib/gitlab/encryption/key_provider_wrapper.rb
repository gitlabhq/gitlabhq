# frozen_string_literal: true

module Gitlab
  module Encryption
    class KeyProviderWrapper
      attr_reader :key_provider

      def initialize(key_provider)
        @key_provider = key_provider
      end

      delegate :encryption_key, to: :key_provider

      def decryption_keys
        key_provider.decryption_keys(ActiveRecord::Encryption::Message.new)
      end

      # Current key first: the order to try keys when looking up or verifying values
      def decryption_keys_current_first
        decryption_keys.reverse
      end
    end
  end
end

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
    end
  end
end

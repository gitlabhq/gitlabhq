# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- General utility
module Gitlab
  class IpAddressState
    THREAD_KEY = :current_ip_address

    class << self
      def with(address)
        set_address(address)
        yield
      ensure
        nullify_address
      end

      def set_address(address)
        self.current = address
      end

      def nullify_address
        self.current = nil
      end

      def current
        Thread.current[THREAD_KEY]
      end

      protected

      def current=(value)
        Thread.current[THREAD_KEY] = value
      end
    end
  end
end
# rubocop: enable Gitlab/NamespacedClass

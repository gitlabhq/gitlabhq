module Gitlab
  class Proxy
    class << self
      # Try to detect possible proxies defined in the OS
      # @return [Hash] of ENV variables that ends with '_proxy' case-insensitive
      def detect_proxy
        env.select { |k, v| /_proxy$/i =~ k }
      end

      private

      def env
        ENV
      end
    end
  end
end

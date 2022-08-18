# frozen_string_literal: true

module Gitlab
  module Auth
    class IpRateLimiter
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :ip

      def initialize(ip)
        @ip = ip
      end

      def reset!
        return if skip_rate_limit?

        Rack::Attack::Allow2Ban.reset(ip, config)
      end

      def register_fail!
        return false if skip_rate_limit?

        # Allow2Ban.filter will return false if this IP has not failed too often yet
        Rack::Attack::Allow2Ban.filter(ip, config) do
          # We return true to increment the count for this IP
          true
        end
      end

      def banned?
        return false if skip_rate_limit?

        Rack::Attack::Allow2Ban.banned?(ip)
      end

      def trusted_ip?
        trusted_ips.any? { |netmask| netmask.include?(ip) }
      end

      private

      def skip_rate_limit?
        !enabled? || trusted_ip?
      end

      def enabled?
        config.enabled
      end

      def config
        Gitlab.config.rack_attack.git_basic_auth
      end

      def trusted_ips
        strong_memoize(:trusted_ips) do
          config.ip_whitelist.map do |proxy|
            IPAddr.new(proxy)
          rescue IPAddr::InvalidAddressError
          end.compact
        end
      end
    end
  end
end

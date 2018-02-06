module Gitlab
  module Auth
    class IpRateLimiter
      attr_reader :ip

      def initialize(ip)
        @ip = ip
        @banned = false
      end

      def enabled?
        config.enabled
      end

      def reset!
        Rack::Attack::Allow2Ban.reset(ip, config)
      end

      def register_fail!
        # Allow2Ban.filter will return false if this IP has not failed too often yet
        @banned = Rack::Attack::Allow2Ban.filter(ip, config) do
          # If we return false here, the failure for this IP is ignored by Allow2Ban
          ip_can_be_banned?
        end
      end

      def banned?
        @banned
      end

      private

      def config
        Gitlab.config.rack_attack.git_basic_auth
      end

      def ip_can_be_banned?
        config.ip_whitelist.exclude?(ip)
      end
    end
  end
end

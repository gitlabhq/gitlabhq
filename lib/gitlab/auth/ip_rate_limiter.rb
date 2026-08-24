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
        increment_ban_metric(:reset)
      end

      def register_fail!
        return false if skip_rate_limit?

        # Allow2Ban.filter will return false if this IP has not failed too often yet
        already_banned = Rack::Attack::Allow2Ban.filter(ip, config) do
          # We return true to increment the count for this IP
          true
        end

        # filter only returns true when the ban already existed, so the attempt that
        # writes the ban is indistinguishable from an ordinary failure without a
        # second read. That true is also the only case that reaches the
        # "threshold exceeded" auth log, so it is counted separately.
        if already_banned
          increment_ban_metric(:already_banned)
        else
          increment_ban_metric(:failure)
          increment_ban_metric(:ban) if Rack::Attack::Allow2Ban.banned?(ip)
        end

        already_banned
      end

      def banned?
        return false if skip_rate_limit?

        Rack::Attack::Allow2Ban.banned?(ip).tap do |banned|
          increment_ban_metric(:blocked) if banned
        end
      end

      def trusted_ip?
        trusted_ips.any? { |netmask| netmask.include?(ip) }
      end

      private

      # Nothing is emitted when the limiter is skipped: an allowlisted or disabled
      # request would tick once per request and bury the ban events.
      def increment_ban_metric(event)
        ban_metric.increment(event: event)
      end

      def ban_metric
        strong_memoize(:ban_metric) do
          ::Gitlab::Metrics.counter(
            :gitlab_rate_limiter_git_basic_auth_ban_events_total,
            'Git and container registry authentication IP ban events.',
            { event: nil }
          )
        end
      end

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
          trusted = config.ip_whitelist.filter_map do |proxy|
            IPAddr.new(proxy)
          rescue IPAddr::InvalidAddressError
            nil
          end

          trusted += trusted.select(&:ipv4?).map(&:ipv4_mapped)

          trusted.uniq
        end
      end
    end
  end
end

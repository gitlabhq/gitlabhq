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

        if labkit_ban?
          GitBasicAuthBan.clear!(ip)
        else
          Rack::Attack::Allow2Ban.reset(ip, config)
        end

        increment_ban_metric(:reset)
      end

      def register_fail!
        return false if skip_rate_limit?
        return register_labkit_fail! if labkit_ban?

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

        banned = labkit_ban? ? GitBasicAuthBan.banned?(ip) : Rack::Attack::Allow2Ban.banned?(ip)

        increment_ban_metric(:blocked) if banned

        banned
      end

      def trusted_ip?
        trusted_ips.any? { |netmask| netmask.include?(ip) }
      end

      private

      # Labkit counts and bans in one call, and suppresses counting while a ban
      # holds, so it cannot separate "already banned" from "banned by this
      # attempt" the way the Allow2Ban path does. Both report :ban.
      #
      # The return value therefore differs: Allow2Ban returns false on the
      # attempt that writes the ban, this returns true. Gitlab::Auth#rate_limit!
      # branches on it to write the "threshold exceeded" auth log, so that log
      # now fires when the ban is created rather than on the next attempt. That
      # is deliberate: on the Allow2Ban path it only fires when a concurrent
      # request banned the IP first, which is why production sees almost none.
      def register_labkit_fail!
        banned = GitBasicAuthBan.register_fail!(ip)

        increment_ban_metric(:failure)
        increment_ban_metric(:ban) if banned

        banned
      end

      def labkit_ban?
        ::Feature.enabled?(:use_labkit_git_basic_auth_ban, ::Feature.current_request,
          type: :gitlab_com_derisk)
      end

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

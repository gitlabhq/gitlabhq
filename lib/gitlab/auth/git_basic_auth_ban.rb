# frozen_string_literal: true

module Gitlab
  module Auth
    # Bans an IP from Git and container registry authentication after repeated
    # failures, backed by Labkit::RateLimit. Used by IpRateLimiter.
    #
    # The three operations map onto labkit as:
    #
    #   banned?        -> peek   (reads the ban without counting)
    #   register_fail! -> check  (counts, and bans on crossing the limit)
    #   clear!         -> clear  (drops the counter and the ban)
    #
    # Configured by rack_attack.git_basic_auth in gitlab.yml. limit and period
    # are resolved per check. bantime is resolved once, because it decides
    # whether the rule carries ban_for at all.
    #
    # The IP allowlist is applied by IpRateLimiter in Ruby rather than by a
    # :skip rule here: entries are netmasks, and labkit matchers do equality,
    # regex or set membership, none of which express CIDR containment.
    module GitBasicAuthBan
      LIMITER_NAME = 'git_basic_auth'
      RULE_NAME = 'failed_auth_ban_by_ip'

      class << self
        # True when this IP is already banned. Does not count.
        def banned?(ip)
          limiter.peek({ ip: ip }).action == :block
        end

        # Counts one failed attempt. True when the IP is banned as a result,
        # or was already banned when the attempt arrived.
        def register_fail!(ip)
          limiter.check({ ip: ip }).action == :block
        end

        # Drops the failure counter and any ban for this IP.
        def clear!(ip)
          limiter.clear({ ip: ip })
        end

        # Test hook: the limiter is memoized for the life of the process.
        def reset_limiter!
          @limiter = nil
        end

        private

        def limiter
          @limiter ||= ::Labkit::RateLimit::Limiter.new(
            name: LIMITER_NAME,
            rules: [ban_rule],
            redis: ::Gitlab::Redis::RateLimiting,
            logger: ::Gitlab::AppLogger
          )
        end

        # ban_for is a modifier rather than an action: :limit enforces the ban,
        # and switching this rule to :log would shadow it without blocking.
        #
        # A bantime under one second means no bans at all. Labkit rejects it,
        # which would fail the whole rule open and stop it counting; without
        # ban_for it stays an ordinary windowed limit that still blocks.
        #
        # Read with [] rather than the reader, which raises MissingConfig on a
        # partially stubbed config. 1_settings.rb always defaults it in
        # production, so only specs can reach the nil.
        def ban_rule
          bantime = config[:bantime].to_i

          ::Labkit::RateLimit::Rule.new(
            name: RULE_NAME,
            action: :limit,
            limit: ->(_context) { config.maxretry },
            period: ->(_context) { config.findtime.to_i },
            ban_for: (bantime if bantime >= 1),
            characteristics: [:ip]
          )
        end

        def config
          Gitlab.config.rack_attack.git_basic_auth
        end
      end
    end
  end
end

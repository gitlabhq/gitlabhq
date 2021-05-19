# frozen_string_literal: true

# When adding new user-configurable throttles, remember to update the documentation
# in doc/user/admin_area/settings/user_and_ip_rate_limits.md
#
# Integration specs for throttling can be found in:
# spec/requests/rack_attack_global_spec.rb
module Gitlab
  module RackAttack
    def self.configure(rack_attack)
      # This adds some methods used by our throttles to the `Rack::Request`
      rack_attack::Request.include(Gitlab::RackAttack::Request)

      # This is Rack::Attack::DEFAULT_THROTTLED_RESPONSE, modified to allow a custom response
      rack_attack.throttled_response = lambda do |env|
        throttled_headers = Gitlab::RackAttack.throttled_response_headers(
          env['rack.attack.matched'], env['rack.attack.match_data']
        )
        [429, { 'Content-Type' => 'text/plain' }.merge(throttled_headers), [Gitlab::Throttle.rate_limiting_response_text]]
      end

      rack_attack.cache.store = Gitlab::RackAttack::InstrumentedCacheStore.new

      # Configure the throttles
      configure_throttles(rack_attack)

      configure_user_allowlist
    end

    # Rate Limit HTTP headers are not standardized anywhere. This is the latest
    # draft submitted to IETF:
    # https://github.com/ietf-wg-httpapi/ratelimit-headers/blob/main/draft-ietf-httpapi-ratelimit-headers.md
    #
    # This method implement the most viable parts of the headers. Those headers
    # will be sent back to the client when it gets throttled.
    #
    # - RateLimit-Limit: indicates the request quota associated to the client
    # in 60 seconds. The time window for the quota here is supposed to be
    # mirrored to throttle_*_period_in_seconds application settings.  However,
    # our HAProxy as well as some ecosystem libraries are using a fixed
    # 60-second window. Therefore, the returned limit is approximately rounded
    # up to fit into that window.
    #
    # - RateLimit-Observed: indicates the current request amount associated to
    # the client within the time window.
    #
    # - RateLimit-Remaining: indicates the remaining quota within the time
    # window. It is the result of RateLimit-Limit - RateLimit-Remaining
    #
    # - Retry-After: the remaining duration in seconds until the quota is
    # reset. This is a standardized HTTP header:
    # https://tools.ietf.org/html/rfc7231#page-69
    #
    # - RateLimit-Reset: the point of time that the request quota is reset, in Unix time
    #
    # - RateLimit-ResetTime: the point of time that the request quota is reset, in HTTP date format
    def self.throttled_response_headers(matched, match_data)
      # Match data example:
      # {:discriminator=>"127.0.0.1", :count=>12, :period=>60 seconds, :limit=>1, :epoch_time=>1609833930}
      # Source: https://github.com/rack/rack-attack/blob/v6.3.0/lib/rack/attack/throttle.rb#L33
      period = match_data[:period]
      limit = match_data[:limit]
      rounded_limit = (limit.to_f * 1.minute / match_data[:period]).ceil
      observed = match_data[:count]
      now = match_data[:epoch_time]
      retry_after = period - (now % period)
      reset_time = Time.at(now + retry_after) # rubocop:disable Rails/TimeZone
      {
        'RateLimit-Name' => matched.to_s,
        'RateLimit-Limit' => rounded_limit.to_s,
        'RateLimit-Observed' => observed.to_s,
        'RateLimit-Remaining' => (limit > observed ? limit - observed : 0).to_s,
        'RateLimit-Reset' => reset_time.to_i.to_s,
        'RateLimit-ResetTime' => reset_time.httpdate,
        'Retry-After' => retry_after.to_s
      }
    end

    def self.configure_user_allowlist
      @user_allowlist = nil
      user_allowlist
    end

    def self.configure_throttles(rack_attack)
      throttle_or_track(rack_attack, 'throttle_unauthenticated', Gitlab::Throttle.unauthenticated_options) do |req|
        if req.throttle_unauthenticated?
          req.ip
        end
      end

      throttle_or_track(rack_attack, 'throttle_authenticated_api', Gitlab::Throttle.authenticated_api_options) do |req|
        if req.throttle_authenticated_api?
          req.throttled_user_id([:api])
        end
      end

      # Product analytics feature is in experimental stage.
      # At this point we want to limit amount of events registered
      # per application (aid stands for application id).
      throttle_or_track(rack_attack, 'throttle_product_analytics_collector', limit: 100, period: 60) do |req|
        if req.product_analytics_collector_request?
          req.params['aid']
        end
      end

      throttle_or_track(rack_attack, 'throttle_authenticated_web', Gitlab::Throttle.authenticated_web_options) do |req|
        if req.throttle_authenticated_web?
          req.throttled_user_id([:api, :rss, :ics])
        end
      end

      throttle_or_track(rack_attack, 'throttle_unauthenticated_protected_paths', Gitlab::Throttle.protected_paths_options) do |req|
        if req.throttle_unauthenticated_protected_paths?
          req.ip
        end
      end

      throttle_or_track(rack_attack, 'throttle_authenticated_protected_paths_api', Gitlab::Throttle.protected_paths_options) do |req|
        if req.throttle_authenticated_protected_paths_api?
          req.throttled_user_id([:api])
        end
      end

      throttle_or_track(rack_attack, 'throttle_authenticated_protected_paths_web', Gitlab::Throttle.protected_paths_options) do |req|
        if req.throttle_authenticated_protected_paths_web?
          req.throttled_user_id([:api, :rss, :ics])
        end
      end

      throttle_or_track(rack_attack, 'throttle_unauthenticated_packages_api', Gitlab::Throttle.unauthenticated_packages_api_options) do |req|
        if req.throttle_unauthenticated_packages_api?
          req.ip
        end
      end

      throttle_or_track(rack_attack, 'throttle_authenticated_packages_api', Gitlab::Throttle.authenticated_packages_api_options) do |req|
        if req.throttle_authenticated_packages_api?
          req.throttled_user_id([:api])
        end
      end

      rack_attack.safelist('throttle_bypass_header') do |req|
        Gitlab::Throttle.bypass_header.present? &&
          req.get_header(Gitlab::Throttle.bypass_header) == '1'
      end
    end

    def self.throttle_or_track(rack_attack, throttle_name, *args, &block)
      if track?(throttle_name)
        rack_attack.track(throttle_name, *args, &block)
      else
        rack_attack.throttle(throttle_name, *args, &block)
      end
    end

    def self.track?(name)
      dry_run_config = ENV['GITLAB_THROTTLE_DRY_RUN'].to_s.strip

      return false if dry_run_config.empty?
      return true if dry_run_config == '*'

      dry_run_config.split(',').map(&:strip).include?(name)
    end

    def self.user_allowlist
      @user_allowlist ||= begin
        list = UserAllowlist.new(ENV['GITLAB_THROTTLE_USER_ALLOWLIST'])
        Gitlab::AuthLogger.info(gitlab_throttle_user_allowlist: list.to_a)
        list
      end
    end
  end
end
::Gitlab::RackAttack.prepend_mod_with('Gitlab::RackAttack')

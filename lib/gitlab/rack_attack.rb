# frozen_string_literal: true

# Integration specs for throttling can be found in:
# spec/requests/rack_attack_global_spec.rb
module Gitlab
  module RackAttack
    def self.configure(rack_attack)
      # This adds some methods used by our throttles to the `Rack::Request`
      rack_attack::Request.include(Gitlab::RackAttack::Request)
      # Send the Retry-After header so clients (e.g. python-gitlab) can make good choices about delays
      Rack::Attack.throttled_response_retry_after_header = true
      # Configure the throttles
      configure_throttles(rack_attack)
    end

    def self.configure_throttles(rack_attack)
      throttle_or_track(rack_attack, 'throttle_unauthenticated', Gitlab::Throttle.unauthenticated_options) do |req|
        if !req.should_be_skipped? &&
           Gitlab::Throttle.settings.throttle_unauthenticated_enabled &&
           req.unauthenticated?
          req.ip
        end
      end

      throttle_or_track(rack_attack, 'throttle_authenticated_api', Gitlab::Throttle.authenticated_api_options) do |req|
        if req.api_request? &&
           Gitlab::Throttle.settings.throttle_authenticated_api_enabled
          req.authenticated_user_id([:api])
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
        if req.web_request? &&
           Gitlab::Throttle.settings.throttle_authenticated_web_enabled
          req.authenticated_user_id([:api, :rss, :ics])
        end
      end

      throttle_or_track(rack_attack, 'throttle_unauthenticated_protected_paths', Gitlab::Throttle.protected_paths_options) do |req|
        if req.post? &&
           !req.should_be_skipped? &&
           req.protected_path? &&
           Gitlab::Throttle.protected_paths_enabled? &&
           req.unauthenticated?
          req.ip
        end
      end

      throttle_or_track(rack_attack, 'throttle_authenticated_protected_paths_api', Gitlab::Throttle.protected_paths_options) do |req|
        if req.post? &&
           req.api_request? &&
           req.protected_path? &&
           Gitlab::Throttle.protected_paths_enabled?
          req.authenticated_user_id([:api])
        end
      end

      throttle_or_track(rack_attack, 'throttle_authenticated_protected_paths_web', Gitlab::Throttle.protected_paths_options) do |req|
        if req.post? &&
           req.web_request? &&
           req.protected_path? &&
           Gitlab::Throttle.protected_paths_enabled?
          req.authenticated_user_id([:api, :rss, :ics])
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
  end
end
::Gitlab::RackAttack.prepend_if_ee('::EE::Gitlab::RackAttack')

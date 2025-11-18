# frozen_string_literal: true

# When adding new user-configurable throttles, remember to update the documentation
# in doc/administration/settings/user_and_ip_rate_limits.md
#
# Integration specs for throttling can be found in:
# spec/requests/rack_attack_global_spec.rb
module Gitlab
  module RackAttack
    def self.configure(rack_attack)
      # This adds some methods used by our throttles to the `Rack::Request`
      rack_attack::Request.include(Gitlab::RackAttack::Request)

      # This is Rack::Attack::DEFAULT_THROTTLED_RESPONSE, modified to allow a custom response
      rack_attack.throttled_responder = ->(request) do
        throttled_headers = Gitlab::RackAttack::RequestThrottleData.from_rack_attack(
          request.env['rack.attack.matched'], request.env['rack.attack.match_data']
        )&.throttled_response_headers
        [429, { 'Content-Type' => 'text/plain' }.merge(throttled_headers || {}), [Gitlab::Throttle.rate_limiting_response_text]]
      end

      rack_attack.cache.store = Gitlab::RackAttack::Store.new

      configure_throttles(rack_attack)
      configure_user_allowlist
    end

    def self.configure_user_allowlist
      @user_allowlist = nil
      user_allowlist
    end

    ThrottleDefinition = Struct.new(:options, :request_identifier)

    def self.throttle_definitions
      {
        'throttle_unauthenticated_web' => ThrottleDefinition.new(
          Gitlab::Throttle.unauthenticated_web_options,
          ->(req) { req.ip if req.throttle_unauthenticated_web? }
        ),
        # Product analytics feature is in experimental stage.
        # At this point we want to limit amount of events registered
        # per application (aid stands for application id).
        'throttle_product_analytics_collector' => ThrottleDefinition.new(
          { limit: 100, period: 60 },
          ->(req) { req.params['aid'] if req.product_analytics_collector_request? }
        ),
        'throttle_authenticated_web' => ThrottleDefinition.new(
          Gitlab::Throttle.authenticated_web_options,
          ->(req) { req.throttled_identifer([:api, :rss, :ics]) if req.throttle_authenticated_web? }
        ),
        'throttle_unauthenticated_protected_paths' => ThrottleDefinition.new(
          Gitlab::Throttle.protected_paths_options,
          ->(req) { req.ip if req.throttle_unauthenticated_protected_paths? }
        ),
        'throttle_authenticated_protected_paths_api' => ThrottleDefinition.new(
          Gitlab::Throttle.protected_paths_options,
          ->(req) { req.throttled_identifer([:api]) if req.throttle_authenticated_protected_paths_api? }
        ),
        'throttle_authenticated_protected_paths_web' => ThrottleDefinition.new(
          Gitlab::Throttle.protected_paths_options,
          ->(req) { req.throttled_identifer([:api, :rss, :ics]) if req.throttle_authenticated_protected_paths_web? }
        ),
        'throttle_unauthenticated_get_protected_paths' => ThrottleDefinition.new(
          Gitlab::Throttle.protected_paths_options,
          ->(req) { req.ip if req.throttle_unauthenticated_get_protected_paths? }
        ),
        'throttle_authenticated_get_protected_paths_api' => ThrottleDefinition.new(
          Gitlab::Throttle.protected_paths_options,
          ->(req) { req.throttled_identifer([:api]) if req.throttle_authenticated_get_protected_paths_api? }
        ),
        'throttle_authenticated_get_protected_paths_web' => ThrottleDefinition.new(
          Gitlab::Throttle.protected_paths_options,
          ->(req) { req.throttled_identifer([:api, :rss, :ics]) if req.throttle_authenticated_get_protected_paths_web? }
        ),
        'throttle_authenticated_git_lfs' => ThrottleDefinition.new(
          Gitlab::Throttle.throttle_authenticated_git_lfs_options,
          ->(req) { req.throttled_identifer([:api]) if req.throttle_authenticated_git_lfs? }
        ),
        **throttle_definitions_unauthenticated_git_http,
        **throttle_definitions_authenticated_git_http
      }
    end

    def self.throttle_definitions_unauthenticated_git_http
      {
        'throttle_unauthenticated_git_http' => ThrottleDefinition.new(
          Gitlab::Throttle.throttle_unauthenticated_git_http_options,
          ->(req) { req.ip if req.throttle_unauthenticated_git_http? }
        )
      }
    end

    def self.throttle_definitions_authenticated_git_http
      {
        'throttle_authenticated_git_http' => ThrottleDefinition.new(
          Gitlab::Throttle.throttle_authenticated_git_http_options,
          ->(req) { req.throttled_identifer([:api]) if req.throttle_authenticated_git_http? }
        )
      }
    end

    def self.configure_throttles(rack_attack)
      # Each of these settings follows the same pattern of specifying separate
      # authenticated and unauthenticated rates via settings
      Gitlab::Throttle::REGULAR_THROTTLES.each do |throttle|
        unauthenticated_options = Gitlab::Throttle.options(throttle, authenticated: false)
        throttle_or_track(rack_attack, "throttle_unauthenticated_#{throttle}", unauthenticated_options) do |req|
          if req.throttle?(throttle, authenticated: false)
            req.ip
          end
        end

        authenticated_options = Gitlab::Throttle.options(throttle, authenticated: true)
        throttle_or_track(rack_attack, "throttle_authenticated_#{throttle}", authenticated_options) do |req|
          if req.throttle?(throttle, authenticated: true)
            req.throttled_identifer([:api])
          end
        end
      end

      throttle_definitions.each do |name, definition|
        throttle_or_track(rack_attack, name, definition.options, &definition.request_identifier)
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

      dry_run_throttles = dry_run_config.split(',').map(&:strip)

      # `throttle_unauthenticated` was split into API and web, so to maintain backwards-compatibility
      # this throttle name now controls both rate limits.
      if dry_run_throttles.include?('throttle_unauthenticated')
        dry_run_throttles += %w[throttle_unauthenticated_api throttle_unauthenticated_web]
      end

      dry_run_throttles.include?(name)
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

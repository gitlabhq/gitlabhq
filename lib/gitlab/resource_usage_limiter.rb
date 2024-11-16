# frozen_string_literal: true

module Gitlab
  class ResourceUsageLimiter # rubocop:disable Gitlab/NamespacedClass -- global wrapper over ApplicationRateLimiter
    def initialize(worker_name: nil)
      # Sidekiq runtime should define worker_name
      # Puma runtime can use caller_id in labkit
      @params = { worker_name: worker_name }.merge(Gitlab::ApplicationContext.current)
    end

    def exceeded_limits
      limits.filter do |limit|
        throttled?(limit)
      end
    end

    private

    def limits
      return [] unless @params[:worker_name]

      Gitlab::SidekiqLimits.limits_for(@params[:worker_name])
    end

    def throttled?(limit)
      # Return false as some scopes are missing avoid inflating another limit's count
      scope = limit.scopes.filter_map { |sk| @params[sk.to_sym] }
      return false if scope.size != limit.scopes.size

      Gitlab::ApplicationRateLimiter.resource_usage_throttled?(
        limit.name,
        resource_key: limit.resource_key,
        scope: scope,
        threshold: limit.threshold,
        interval: limit.interval
      )
    end
  end
end

# frozen_string_literal: true

module WorkItems
  class DeleteService < Issues::DestroyService
    RATE_LIMIT_KEY = :work_item_delete

    def execute(work_item)
      check_rate_limit!

      unless current_user.can?(:delete_work_item, work_item)
        return ::ServiceResponse.error(message: 'User not authorized to delete work item')
      end

      if super
        ::ServiceResponse.success
      else
        ::ServiceResponse.error(message: work_item.errors.full_messages)
      end
    end

    private

    def check_rate_limit!
      return unless ::Feature.enabled?(:work_item_delete_rate_limit, current_user)
      return unless ::Gitlab::ApplicationRateLimiter.throttled?(RATE_LIMIT_KEY, scope: { user: current_user })

      raise ::RateLimitedService::RateLimitedError.new(
        key: RATE_LIMIT_KEY, rate_limiter: ::Gitlab::ApplicationRateLimiter
      ), ::Gitlab::ApplicationRateLimiter.throttled_error_message
    end
  end
end

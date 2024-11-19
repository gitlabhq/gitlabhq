# frozen_string_literal: true

module LoopWithRuntimeLimit # rubocop:disable Gitlab/BoundedContexts -- it's a general purpose module
  private

  def loop_with_runtime_limit(time_limit)
    runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(time_limit)
    loop do
      yield runtime_limiter

      break :over_time if runtime_limiter.was_over_time? || runtime_limiter.over_time?
    end
  end
end

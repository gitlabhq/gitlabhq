# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module SizeLimiter
      # A custom exception for size limiter. It contains worker class and its
      # size to easier track later
      class ExceedLimitError < StandardError
        attr_reader :worker_class, :size, :size_limit

        def initialize(worker_class, size, size_limit)
          @worker_class = worker_class
          @size = size
          @size_limit = size_limit

          super "#{@worker_class} job exceeds payload size limit"
        end

        def sentry_extra_data
          {
            worker_class: @worker_class.to_s,
            size: @size.to_i,
            size_limit: @size_limit.to_i
          }
        end
      end
    end
  end
end

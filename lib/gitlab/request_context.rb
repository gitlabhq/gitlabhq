# frozen_string_literal: true

module Gitlab
  class RequestContext
    include Gitlab::Utils::StrongMemoize
    include Singleton

    RequestDeadlineExceeded = Class.new(StandardError)

    attr_accessor :client_ip, :start_thread_cpu_time, :request_start_time, :thread_memory_allocations

    class << self
      def instance
        Gitlab::SafeRequestStore[:request_context] ||= new
      end
    end

    def request_deadline
      strong_memoize(:request_deadline) do
        next unless request_start_time

        request_start_time + max_request_duration_seconds
      end
    end

    def ensure_deadline_not_exceeded!
      return unless enabled?
      return unless request_deadline
      return if Gitlab::Metrics::System.real_time < request_deadline

      raise RequestDeadlineExceeded,
            "Request takes longer than #{max_request_duration_seconds} seconds"
    end

    private

    def max_request_duration_seconds
      Settings.gitlab.max_request_duration_seconds
    end

    def enabled?
      !Rails.env.test?
    end
  end
end

# frozen_string_literal: true

module Gitlab
  class RequestContext
    include Singleton

    RequestDeadlineExceeded = Class.new(StandardError)

    attr_accessor :client_ip, :start_thread_cpu_time, :request_start_time

    class << self
      def instance
        Gitlab::SafeRequestStore[:request_context] ||= new
      end
    end

    def request_deadline
      return unless request_start_time
      return unless Feature.enabled?(:request_deadline)

      @request_deadline ||= request_start_time + max_request_duration_seconds
    end

    def ensure_deadline_not_exceeded!
      return unless request_deadline
      return if Gitlab::Metrics::System.real_time < request_deadline

      raise RequestDeadlineExceeded,
            "Request takes longer than #{max_request_duration_seconds}"
    end

    private

    def max_request_duration_seconds
      Settings.gitlab.max_request_duration_seconds
    end
  end
end

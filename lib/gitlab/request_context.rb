# frozen_string_literal: true

module Gitlab
  class RequestContext
    include Gitlab::Utils::StrongMemoize
    include Singleton

    RequestDeadlineExceeded = Class.new(StandardError)

    attr_accessor :client_ip, :spam_params, :start_thread_cpu_time, :request_start_time, :thread_memory_allocations

    class << self
      def instance
        Gitlab::SafeRequestStore[:request_context] ||= new
      end

      def start_request_context(request:)
        # We need to use Rack::Request to be consistent with Rails due to a Rails bug described in
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/58573#note_149799010
        # Hosts behind a load balancer will only see 127.0.0.1 for the load balancer's IP.
        rack_req = Rack::Request.new(request.env)
        instance.client_ip = rack_req.ip

        instance.spam_params = ::Spam::SpamParams.new_from_request(request: request)
        instance.request_start_time = Gitlab::Metrics::System.real_time
      end

      def start_thread_context
        instance.start_thread_cpu_time = Gitlab::Metrics::System.thread_cpu_time
        instance.thread_memory_allocations = Gitlab::Memory::Instrumentation.start_thread_memory_allocations
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

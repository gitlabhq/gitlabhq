# frozen_string_literal: true

module ErrorTracking
  class CollectErrorService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      error_repository.report_error(
        name: exception['type'],
        description: exception['value'],
        actor: actor,
        platform: event['platform'],
        occurred_at: timestamp,
        environment: event['environment'],
        level: event['level'],
        payload: event
      )
    end

    private

    def error_repository
      Gitlab::ErrorTracking::ErrorRepository.build(project)
    end

    def event
      @event ||= format_event(params[:event])
    end

    def format_event(event)
      # Some SDK send exception payload as Array. For exmple Go lang SDK.
      # We need to convert it to hash format we expect.
      if event['exception'].is_a?(Array)
        exception = event['exception']
        event['exception'] = { 'values' => exception }
      end

      event
    end

    def exception
      strong_memoize(:exception) do
        # Find the first exception that has a stacktrace since the first
        # exception may not provide adequate context (e.g. in the Go SDK).
        entries = event['exception']['values']
        entries.find { |x| x.key?('stacktrace') } || entries.first
      end
    end

    def stacktrace_frames
      strong_memoize(:stacktrace_frames) do
        exception.dig('stacktrace', 'frames')
      end
    end

    def actor
      return event['transaction'] if event['transaction'].present?

      # Some SDKs do not have a transaction attribute.
      # So we build it by combining function name and module name from
      # the last item in stacktrace.
      return unless stacktrace_frames.present?

      last_line = stacktrace_frames.last

      "#{last_line['function']}(#{last_line['module']})"
    end

    def timestamp
      return @timestamp if @timestamp

      @timestamp = (event['timestamp'] || Time.zone.now)

      # Some SDK send timestamp in numeric format like '1630945472.13'.
      if @timestamp.to_s =~ /\A\d+(\.\d+)?\z/
        @timestamp = Time.zone.at(@timestamp.to_f)
      end

      @timestamp
    end
  end
end

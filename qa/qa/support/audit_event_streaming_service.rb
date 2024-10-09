# frozen_string_literal: true

module QA
  module Support
    class AuditEventStreamingService
      def initialize(wait: 10, reset_on_init: true)
        @mocks = File.read(EE::Runtime::Path.fixture('audit_event_streaming', 'mocks.yml'))

        # We use the time of initialization to limit the results we get from the audit events API
        @start = DateTime.now.iso8601
        @smocker_container = Service::DockerRun::Smocker.create
        @api = Vendor::Smocker::SmockerApi.new(
          host: @smocker_container.host_name,
          public_port: @smocker_container.public_port,
          admin_port: @smocker_container.admin_port
        )
        @api.wait_for_ready(wait: wait)
        @api.reset if reset_on_init
        @api.register(mocks)
      end

      delegate :verify, to: :api

      # Fetch smocker container logs
      #
      # @return [String]
      def container_logs
        smocker_container.logs
      end

      # Reset mock definitions
      #
      # @return [void]
      def reset!
        api.reset
        api.register(mocks)
      end

      # Remove the Smocker Docker container
      #
      # @return [void]
      def teardown!
        smocker_container&.remove!
      end

      # Stream destination url
      #
      # @return [String]
      def destination_url
        @logs_endpoint ||= api.url('logs')
      end

      # Wait for the mock service to receive a request with the specified event type
      #
      # @param [Symbol] event_type the event to wait for
      # @param [String] entity_type the entity type of the event
      # @param [String] entity_path the event entity identifier
      # @param [Integer] wait the amount of time to wait for the event to be received
      # @param [Boolean] raise_on_failure raise an error if the event is not received
      # @return [Hash] the request
      def wait_for_event(event_type, entity_type, entity_path = nil, wait: 10, raise_on_failure: true)
        event = Waiter.wait_until(max_duration: wait, sleep_interval: 1, raise_on_failure: false) do
          api.history.find do |record|
            body = record.request[:body]
            next if body.blank?

            body&.dig(:event_type) == event_type.to_s &&
              body&.dig(:entity_type) == entity_type &&
              (!entity_path || body&.dig(:entity_path) == entity_path)
          end&.request
        end
        return event unless event.nil? && raise_on_failure

        # Get the audit events from the API to help troubleshoot failures
        audit_events = EE::Resource::AuditEvents.all(created_after: @start, entity_type: entity_type)

        raise Repeater::WaitExceededError,
          "An event with type '#{event_type}'#{" and entity_path '#{entity_path}'" if entity_path} was not received. " \
            "Event history: #{stringified_history}. " \
            "Audit events with entity_type '#{entity_type}': #{audit_events}"
      end

      # Wait for GitLab to start streaming audit events and for the Smocker server to be ready to receive them.
      #
      # When we start the mock streaming server it sometimes doesn't start receiving traffic immediately, even
      # when the smocker API reports that it's ready. In addition, there can be a brief delay after a new streaming
      # destination is configured before it sends events.
      def wait_for_streaming_to_start(event_type:, entity_type:)
        # Create and then remove an SSH key and confirm that the mock streaming server received the event
        Waiter.wait_until(max_duration: 60, sleep_interval: 5, message: 'Waiting for streaming to start') do
          yield

          wait_for_event(event_type, entity_type, wait: 2, raise_on_failure: false)
        end
      rescue Repeater::WaitExceededError
        # If there is a failure this will output the logs from the smocker container (at the debug log level)
        container_logs

        raise
      end

      private

      attr_reader :mocks, :smocker_container, :api
    end
  end
end

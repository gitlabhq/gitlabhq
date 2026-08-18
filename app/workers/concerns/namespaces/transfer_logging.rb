# frozen_string_literal: true

module Namespaces
  # Shared structured-logging helper for namespace transfer services and workers.
  #
  # Produces a standardised payload for transfer log entries (Part 9 of
  # https://gitlab.com/gitlab-org/gitlab/-/work_items/586550).
  #
  # Field provenance:
  #
  # - `correlation_id`, `error_message`, `duration_s`, `gl_namespace_id`, and
  #   `error_type` map to the standard LabKit Ruby Fields and follow
  #   project-wide log field standards.
  # - `namespace_type`, `transfer_state`, `initiated_via`, `queue_wait_s`, and
  #   `retry_count` are intentionally service-specific to the transfer
  #   domain; they describe properties of a namespace transfer that have no
  #   counterpart in shared LabKit fields.
  module TransferLogging
    extend ActiveSupport::Concern

    include Gitlab::Loggable

    private

    # Builds a standardised structured log payload for a transfer event.
    #
    # @param message [String] human-readable log message
    # @param namespace [Namespace, nil] the namespace being transferred
    # @param error [Exception, nil] the exception that caused a failure, if any
    # @param extra [Hash] additional caller-specific key/value pairs merged into
    #   the payload; recognised optional keys: :initiated_via, :duration_s,
    #   :queue_wait_s, :retry_count
    # @return [Hash] stringified structured payload ready to pass to a logger
    def build_transfer_log_payload(message:, namespace: nil, error: nil, **extra)
      payload = {
        message: message,
        correlation_id: Labkit::Correlation::CorrelationId.current_or_new_id,
        gl_namespace_id: namespace&.id,
        namespace_type: transfer_namespace_type(namespace),
        transfer_state: namespace&.state,
        initiated_via: extra.delete(:initiated_via),
        duration_s: extra.delete(:duration_s),
        queue_wait_s: extra.delete(:queue_wait_s),
        retry_count: extra.delete(:retry_count),
        error_type: error&.class&.name,
        error_message: error&.message
      }.merge(extra)

      build_structured_payload_labkit(**payload)
    end

    # Returns a canonical string for the namespace type used in log payloads.
    def transfer_namespace_type(namespace)
      return unless namespace

      case namespace
      when ::Group then 'group'
      when ::Namespaces::ProjectNamespace then 'project'
      else namespace.class.name
      end
    end

    # Returns elapsed wall-clock seconds since +start_time+ with microsecond
    # precision, suitable for the +duration_s+ log field.
    def elapsed_seconds(start_time)
      (Gitlab::Metrics::System.monotonic_time - start_time).round(6)
    end
  end
end

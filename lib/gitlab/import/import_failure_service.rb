# frozen_string_literal: true

module Gitlab
  module Import
    class ImportFailureService
      def self.track(
        exception:,
        import_state: nil,
        project_id: nil,
        error_source: nil,
        fail_import: false,
        metrics: false,
        external_identifiers: {}
      )
        new(
          exception: exception,
          import_state: import_state,
          project_id: project_id,
          error_source: error_source,
          fail_import: fail_import,
          metrics: metrics,
          external_identifiers: external_identifiers
        ).execute
      end

      def initialize(
        exception:,
        import_state: nil,
        project_id: nil,
        error_source: nil,
        fail_import: false,
        metrics: false,
        external_identifiers: {}
      )

        if import_state.blank? && project_id.blank?
          raise ArgumentError, 'import_state OR project_id must be provided'
        end

        if project_id.blank?
          @import_state = import_state
          @project = import_state.project
        else
          @project = Project.find(project_id)
          @import_state = @project.import_state
        end

        @exception = exception
        @error_source = error_source
        @fail_import = fail_import
        @metrics = metrics
        @external_identifiers = external_identifiers
      end

      def execute
        track_exception
        persist_failure.tap do
          import_state.mark_as_failed(exception.message) if fail_import
          track_metrics if metrics
        end
      end

      private

      attr_reader :exception, :import_state, :project, :error_source, :fail_import, :metrics, :external_identifiers

      def track_exception
        attributes = {
          import_type: project.import_type,
          project_id: project.id,
          source: error_source,
          external_identifiers: external_identifiers
        }

        ::Import::Framework::Logger.error(
          attributes.merge(
            message: 'importer failed',
            'exception.message': exception.message
          )
        )

        Gitlab::ErrorTracking.track_exception(exception, attributes)
      end

      # Failures with `retry_count: 0` are considered "hard_failures" and those
      # are exposed on the REST API projects/:id/import
      def persist_failure
        project.import_failures.create(
          source: error_source,
          exception_class: exception.class.to_s,
          exception_message: exception.message.truncate(255),
          correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id,
          retry_count: fail_import ? 0 : nil,
          external_identifiers: external_identifiers
        )
      end

      def track_metrics
        Gitlab::Import::Metrics.new("#{project.import_type}_importer", project).track_failed_import
      end
    end
  end
end

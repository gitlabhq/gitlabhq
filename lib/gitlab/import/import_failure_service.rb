# frozen_string_literal: true

module Gitlab
  module Import
    class ImportFailureService
      def self.track(
        exception:,
        import_state: nil,
        project_id: nil,
        error_source: nil,
        fail_import: false
      )
        new(
          exception: exception,
          import_state: import_state,
          project_id: project_id,
          error_source: error_source
        ).execute(fail_import: fail_import)
      end

      def initialize(exception:, import_state: nil, project_id: nil, error_source: nil)
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
      end

      def execute(fail_import:)
        track_exception
        persist_failure

        import_state.mark_as_failed(exception.message) if fail_import
      end

      private

      attr_reader :exception, :import_state, :project, :error_source

      def track_exception
        attributes = {
          import_type: project.import_type,
          project_id: project.id,
          source: error_source
        }

        Gitlab::Import::Logger.error(
          attributes.merge(
            message: 'importer failed',
            'error.message': exception.message
          )
        )

        Gitlab::ErrorTracking.track_exception(exception, attributes)
      end

      def persist_failure
        project.import_failures.create(
          source: error_source,
          exception_class: exception.class.to_s,
          exception_message: exception.message.truncate(255),
          correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
        )
      end
    end
  end
end

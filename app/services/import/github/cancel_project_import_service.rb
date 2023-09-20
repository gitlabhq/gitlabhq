# frozen_string_literal: true

module Import
  module Github
    class CancelProjectImportService < ::BaseService
      def execute
        return error('Not Found', :not_found) unless authorized_to_read?
        return error('Unauthorized access', :forbidden) unless authorized_to_cancel?

        if project.import_state.completed?
          error(cannot_cancel_error_message, :bad_request)
        else
          project.import_state.cancel
          metrics.track_canceled_import

          success(project: project)
        end
      end

      private

      def authorized_to_read?
        can?(current_user, :read_project, project)
      end

      def authorized_to_cancel?
        can?(current_user, :owner_access, project)
      end

      def cannot_cancel_error_message
        format(
          _('The import cannot be canceled because it is %{project_status}'),
          project_status: project.import_state.status
        )
      end

      def metrics
        @metrics ||= Gitlab::Import::Metrics.new(:github_importer, project)
      end
    end
  end
end

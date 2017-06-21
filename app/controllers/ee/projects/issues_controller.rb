module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern

      included do
        before_action :check_export_issues_available!, only: [:export_csv]
      end

      def export_csv
        ExportCsvWorker.perform_async(current_user.id, project.id, filter_params)

        index_path = namespace_project_issues_path(project.namespace, project)
        redirect_to(index_path, notice: "Your CSV export has started. It will be emailed to #{current_user.notification_email} when complete.")
      end
    end
  end
end

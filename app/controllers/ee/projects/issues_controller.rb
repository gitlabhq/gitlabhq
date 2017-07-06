module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern

      prepended do
        before_action :check_export_issues_available!, only: [:export_csv]
      end

      def export_csv
        ExportCsvWorker.perform_async(current_user.id, project.id, filter_params)

        index_path = project_issues_path(project)
        redirect_to(index_path, notice: "Your CSV export has started. It will be emailed to #{current_user.notification_email} when complete.")
      end

      def issue_params_attributes
        attrs = super
        attrs.unshift(:weight) if project.feature_available?(:issue_weights)

        attrs
      end

      def filter_params
        params = super
        params.reject! { |key| key == 'weight' } unless project.feature_available?(:issue_weights)

        params
      end
    end
  end
end

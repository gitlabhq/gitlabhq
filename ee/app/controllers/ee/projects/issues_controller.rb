module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern

      prepended do
        before_action :check_export_issues_available!, only: [:export_csv]
        before_action :check_service_desk_available!, only: [:service_desk]
        before_action :set_issuables_index, only: [:index, :calendar, :service_desk]
        skip_before_action :issue, only: [:service_desk]
      end

      def service_desk
        @issues = @issuables # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @users.push(::User.support_bot) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def export_csv
        ExportCsvWorker.perform_async(current_user.id, project.id, filter_params.to_h)

        index_path = project_issues_path(project)
        redirect_to(index_path, notice: "Your CSV export has started. It will be emailed to #{current_user.notification_email} when complete.")
      end

      private

      def issue_params_attributes
        attrs = super
        attrs.unshift(:weight) if project.feature_available?(:issue_weights)

        attrs
      end

      def filter_params
        params = super
        params.reject! { |key| key == 'weight' } unless project.feature_available?(:issue_weights)

        if service_desk?
          params.reject! { |key| key == 'author_username' || key == 'author_id' }
          params[:author_id] = ::User.support_bot
        end

        params
      end

      def service_desk?
        action_name == 'service_desk'
      end
    end
  end
end

module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern

      prepended do
        before_action :check_export_issues_available!, only: [:export_csv]
        before_action :check_service_desk_available!, only: [:service_desk]
        skip_before_action :issue, only: [:service_desk]
      end

      def service_desk
        @collection_type    = "Issue"
        @issues             = issues_collection

        @issues             = @issues.page(params[:page])
        @issuable_meta_data = issuable_meta_data(@issues, @collection_type)

        if @issues.out_of_range? && @issues.total_pages != 0
          return redirect_to url_for(params.merge(page: @issues.total_pages, only_path: true))
        end

        if params[:label_name].present?
          @labels = LabelsFinder.new(current_user, project_id: @project.id, title: params[:label_name]).execute
        end

        @users = []

        if params[:assignee_id].present?
          assignee = User.find_by_id(params[:assignee_id])
          @users.push(assignee) if assignee
        end

        @users.push(::User.support_bot)
      end

      def export_csv
        ExportCsvWorker.perform_async(current_user.id, project.id, filter_params)

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

        if action_name == 'service_desk'
          params.reject! { |key| key == 'author_username' || key == 'author_id' }
          params[:author_id] = ::User.support_bot
        end

        params
      end

      def self.skip_issue_actions
        super + [:service_desk]
      end
    end
  end
end

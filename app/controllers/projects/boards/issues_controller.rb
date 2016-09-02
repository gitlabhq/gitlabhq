module Projects
  module Boards
    class IssuesController < Boards::ApplicationController
      before_action :authorize_read_issue!, only: [:index]
      before_action :authorize_update_issue!, only: [:update]

      def index
        issues = ::Boards::Issues::ListService.new(project, current_user, filter_params).execute
        issues = issues.page(params[:page])

        render json: {
          issues: issues.as_json(
            only: [:iid, :title, :confidential],
            include: {
              assignee: { only: [:id, :name, :username], methods: [:avatar_url] },
              labels:   { only: [:id, :title, :description, :color, :priority], methods: [:text_color] }
            }),
          size: issues.total_count
        }
      end

      def update
        service = ::Boards::Issues::MoveService.new(project, current_user, move_params)

        if service.execute(issue)
          head :ok
        else
          head :unprocessable_entity
        end
      end

      private

      def issue
        @issue ||=
          IssuesFinder.new(current_user, project_id: project.id, state: 'all')
                      .execute
                      .where(iid: params[:id])
                      .first!
      end

      def authorize_read_issue!
        return render_403 unless can?(current_user, :read_issue, project)
      end

      def authorize_update_issue!
        return render_403 unless can?(current_user, :update_issue, issue)
      end

      def filter_params
        params.merge(id: params[:list_id])
      end

      def move_params
        params.permit(:id, :from_list_id, :to_list_id)
      end
    end
  end
end

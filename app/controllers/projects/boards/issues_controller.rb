module Projects
  module Boards
    class IssuesController < Boards::ApplicationController
      before_action :authorize_read_issue!, only: [:index]
      before_action :authorize_create_issue!, only: [:create]
      before_action :authorize_update_issue!, only: [:update]

      def index
        issues = ::Boards::Issues::ListService.new(project, current_user, filter_params).execute
        issues = issues.page(params[:page])

        render json: {
          issues: serialize_as_json(issues),
          size: issues.total_count
        }
      end

      def create
        list = project.board.lists.find(params[:list_id])
        service = ::Boards::Issues::CreateService.new(project, current_user, issue_params)
        issue = service.execute(list)

        if issue.valid?
          render json: serialize_as_json(issue)
        else
          render json: issue.errors, status: :unprocessable_entity
        end
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
          IssuesFinder.new(current_user, project_id: project.id)
                      .execute
                      .where(iid: params[:id])
                      .first!
      end

      def authorize_read_issue!
        return render_403 unless can?(current_user, :read_issue, project)
      end

      def authorize_create_issue!
        return render_403 unless can?(current_user, :admin_issue, project)
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

      def issue_params
        params.require(:issue).permit(:title).merge(request: request)
      end

      def serialize_as_json(resource)
        resource.as_json(
          only: [:iid, :title, :confidential],
          include: {
            assignee: { only: [:id, :name, :username], methods: [:avatar_url] },
            labels:   { only: [:id, :title, :description, :color, :priority], methods: [:text_color] }
          })
      end
    end
  end
end

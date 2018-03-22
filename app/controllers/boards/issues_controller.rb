module Boards
  class IssuesController < Boards::ApplicationController
    include BoardsResponses
    include ControllerWithCrossProjectAccessCheck

    requires_cross_project_access if: -> { board&.group_board? }

    before_action :whitelist_query_limiting, only: [:index, :update]
    before_action :authorize_read_issue, only: [:index]
    before_action :authorize_create_issue, only: [:create]
    before_action :authorize_update_issue, only: [:update]
    skip_before_action :authenticate_user!, only: [:index]

    def index
      issues = Boards::Issues::ListService.new(board_parent, current_user, filter_params).execute
      issues = issues.page(params[:page]).per(params[:per] || 20)
      make_sure_position_is_set(issues) if Gitlab::Database.read_write?
      issues = issues.preload(:project,
                              :milestone,
                              :assignees,
                              labels: [:priorities],
                              notes: [:award_emoji, :author]
                             )

      render json: {
        issues: serialize_as_json(issues),
        size: issues.total_count
      }
    end

    def create
      service = Boards::Issues::CreateService.new(board_parent, project, current_user, issue_params)
      issue = service.execute

      if issue.valid?
        render json: serialize_as_json(issue)
      else
        render json: issue.errors, status: :unprocessable_entity
      end
    end

    def update
      service = Boards::Issues::MoveService.new(board_parent, current_user, move_params)

      if service.execute(issue)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def make_sure_position_is_set(issues)
      issues.each do |issue|
        issue.move_to_end && issue.save unless issue.relative_position
      end
    end

    def issue
      @issue ||= issues_finder.find(params[:id])
    end

    def filter_params
      params.merge(board_id: params[:board_id], id: params[:list_id])
        .reject { |_, value| value.nil? }
    end

    def issues_finder
      if board.group_board?
        IssuesFinder.new(current_user, group_id: board_parent.id)
      else
        IssuesFinder.new(current_user, project_id: board_parent.id)
      end
    end

    def project
      @project ||= if board.group_board?
                     Project.find(issue_params[:project_id])
                   else
                     board_parent
                   end
    end

    def move_params
      params.permit(:board_id, :id, :from_list_id, :to_list_id, :move_before_id, :move_after_id)
    end

    def issue_params
      params.require(:issue)
        .permit(:title, :milestone_id, :project_id)
        .merge(board_id: params[:board_id], list_id: params[:list_id], request: request)
    end

    def serialize_as_json(resource)
      resource.as_json(
        only: [:id, :iid, :project_id, :title, :confidential, :due_date, :relative_position, :weight],
        labels: true,
        sidebar_endpoints: true,
        include: {
          project: { only: [:id, :path] },
          assignees: { only: [:id, :name, :username], methods: [:avatar_url] },
          milestone: { only: [:id, :title] }
        }
      )
    end

    def whitelist_query_limiting
      # Also see https://gitlab.com/gitlab-org/gitlab-ce/issues/42439
      Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42428')
    end
  end
end

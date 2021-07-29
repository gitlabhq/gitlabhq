# frozen_string_literal: true

module Boards
  class IssuesController < Boards::ApplicationController
    # This is the maximum amount of issues which can be moved by one request to
    # bulk_move for now. This is temporary and might be removed in future by
    # introducing an alternative (async?) approach.
    # (related: https://gitlab.com/groups/gitlab-org/-/epics/382)
    MAX_MOVE_ISSUES_COUNT = 50

    include BoardsResponses
    include ControllerWithCrossProjectAccessCheck

    requires_cross_project_access if: -> { board&.group_board? }

    before_action :disable_query_limiting, only: [:bulk_move]
    before_action :authorize_read_issue, only: [:index]
    before_action :authorize_create_issue, only: [:create]
    before_action :authorize_update_issue, only: [:update]
    skip_before_action :authenticate_user!, only: [:index]
    before_action :validate_id_list, only: [:bulk_move]
    before_action :can_move_issues?, only: [:bulk_move]

    feature_category :boards

    def index
      list_service = Boards::Issues::ListService.new(board_parent, current_user, filter_params)
      issues = issues_from(list_service)

      if Gitlab::Database.main.read_write? && !board.disabled_for?(current_user)
        Issue.move_nulls_to_end(issues)
      end

      render_issues(issues, list_service.metadata)
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

    def bulk_move
      service = Boards::Issues::MoveService.new(board_parent, current_user, move_params(true))

      issues = Issue.find(params[:ids])

      render json: service.execute_multiple(issues)
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

    def issues_from(list_service)
      issues = list_service.execute
      issues.page(params[:page]).per(params[:per] || 20)
            .without_count
            .preload(associations_to_preload) # rubocop: disable CodeReuse/ActiveRecord
            .load
    end

    def associations_to_preload
      [
        :milestone,
        :assignees,
        project: [
            :route,
            {
                namespace: [:route]
            }
        ],
        labels: [:priorities],
        notes: [:award_emoji, :author]
      ]
    end

    def can_move_issues?
      head(:forbidden) unless can?(current_user, :admin_issue, board)
    end

    def serializer_options(issues)
      {}
    end

    def render_issues(issues, metadata)
      data = { issues: serialize_as_json(issues, opts: serializer_options(issues)) }
      data.merge!(metadata)

      render json: data
    end

    def issue
      @issue ||= issues_finder.find(params[:id])
    end

    def filter_params
      params.permit(*Boards::Issues::ListService.valid_params).merge(board_id: params[:board_id], id: params[:list_id])
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

    def move_params(multiple = false)
      id_param = multiple ? :ids : :id
      params.permit(id_param, :board_id, :from_list_id, :to_list_id, :move_before_id, :move_after_id)
    end

    def issue_params
      params.require(:issue)
        .permit(:title, :milestone_id, :project_id)
        .merge(board_id: params[:board_id], list_id: params[:list_id])
    end

    def serializer
      IssueSerializer.new(current_user: current_user)
    end

    def serialize_as_json(resource, opts: {})
      opts.merge!(include_full_project_path: board.group_board?, serializer: 'board')

      serializer.represent(resource, opts)
    end

    def disable_query_limiting
      Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/issues/35174')
    end

    def validate_id_list
      head(:bad_request) unless params[:ids].is_a?(Array)
      head(:unprocessable_entity) if params[:ids].size > MAX_MOVE_ISSUES_COUNT
    end
  end
end

Boards::IssuesController.prepend_mod_with('Boards::IssuesController')

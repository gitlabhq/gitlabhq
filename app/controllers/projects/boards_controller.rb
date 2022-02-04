# frozen_string_literal: true

class Projects::BoardsController < Projects::ApplicationController
  include MultipleBoardsActions
  include IssuableCollections

  before_action :check_issues_available!
  before_action :assign_endpoint_vars
  before_action do
    push_frontend_feature_flag(:issue_boards_filtered_search, project&.group, default_enabled: :yaml)
    push_frontend_feature_flag(:board_multi_select, project, default_enabled: :yaml)
    push_frontend_feature_flag(:iteration_cadences, project&.group, default_enabled: :yaml)
    experiment(:prominent_create_board_btn, subject: current_user) do |e|
      e.control { }
      e.candidate { }
    end.run
  end

  feature_category :team_planning

  private

  def board_klass
    Board
  end

  def boards_finder
    strong_memoize :boards_finder do
      Boards::BoardsFinder.new(parent, current_user)
    end
  end

  def board_finder
    strong_memoize :board_finder do
      Boards::BoardsFinder.new(parent, current_user, board_id: params[:id])
    end
  end

  def board_create_service
    strong_memoize :board_create_service do
      Boards::CreateService.new(parent, current_user)
    end
  end

  def assign_endpoint_vars
    @boards_endpoint = project_boards_path(project)
    @bulk_issues_path = bulk_update_project_issues_path(project)
    @namespace_path = project.namespace.full_path
    @labels_endpoint = project_labels_path(project)
  end

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_issue_board, project)
  end
end

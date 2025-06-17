# frozen_string_literal: true

class Projects::BoardsController < Projects::ApplicationController
  include BoardsActions
  include IssuableCollections

  before_action :check_issues_available!
  before_action do
    push_frontend_feature_flag(:board_multi_select, project)
    push_frontend_feature_flag(:issues_list_drawer, project)
    push_force_frontend_feature_flag(:work_items_beta, !!project&.work_items_beta_feature_flag_enabled?)
    push_frontend_feature_flag(:notifications_todos_buttons, current_user)
    push_force_frontend_feature_flag(:glql_integration, !!project&.glql_integration_feature_flag_enabled?)
    push_force_frontend_feature_flag(:continue_indented_text, !!project&.continue_indented_text_feature_flag_enabled?)
    push_frontend_feature_flag(:work_item_status_feature_flag, project&.root_ancestor)
  end

  feature_category :team_planning
  urgency :low

  private

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

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_issue_board, project)
  end
end

Projects::BoardsController.prepend_mod

# frozen_string_literal: true

class Groups::BoardsController < Groups::ApplicationController
  include BoardsActions
  include RecordUserLastActivity
  include Gitlab::Utils::StrongMemoize

  before_action do
    push_frontend_feature_flag(:board_multi_select, group)
    push_frontend_feature_flag(:issues_list_drawer, group)
    push_force_frontend_feature_flag(:work_items_beta, !!group&.work_items_beta_feature_flag_enabled?)
    push_frontend_feature_flag(:notifications_todos_buttons, current_user)
    push_force_frontend_feature_flag(:glql_integration, !!group&.glql_integration_feature_flag_enabled?)
    push_force_frontend_feature_flag(:continue_indented_text, !!group&.continue_indented_text_feature_flag_enabled?)
    push_frontend_feature_flag(:work_item_status_feature_flag, group&.root_ancestor)
  end

  feature_category :team_planning
  urgency :low

  private

  def board_finder
    Boards::BoardsFinder.new(parent, current_user, board_id: params[:id])
  end
  strong_memoize_attr :board_finder

  def board_create_service
    Boards::CreateService.new(parent, current_user)
  end
  strong_memoize_attr :board_create_service

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_issue_board, group)
  end
end

Groups::BoardsController.prepend_mod

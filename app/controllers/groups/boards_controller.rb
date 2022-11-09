# frozen_string_literal: true

class Groups::BoardsController < Groups::ApplicationController
  include BoardsActions
  include RecordUserLastActivity
  include Gitlab::Utils::StrongMemoize

  before_action do
    push_frontend_feature_flag(:board_multi_select, group)
    push_frontend_feature_flag(:apollo_boards, group)
    experiment(:prominent_create_board_btn, subject: current_user) do |e|
      e.control {}
      e.candidate {}
    end.run
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
    access_denied! unless can?(current_user, :read_issue_board, group)
  end
end

Groups::BoardsController.prepend_mod

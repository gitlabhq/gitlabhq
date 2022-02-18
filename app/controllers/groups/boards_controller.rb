# frozen_string_literal: true

class Groups::BoardsController < Groups::ApplicationController
  include BoardsActions
  include RecordUserLastActivity
  include Gitlab::Utils::StrongMemoize

  before_action :assign_endpoint_vars
  before_action do
    push_frontend_feature_flag(:issue_boards_filtered_search, group, default_enabled: :yaml)
    push_frontend_feature_flag(:board_multi_select, group, default_enabled: :yaml)
    push_frontend_feature_flag(:iteration_cadences, group, default_enabled: :yaml)
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
    @boards_endpoint = group_boards_path(group)
    @namespace_path = group.to_param
    @labels_endpoint = group_labels_path(group)
  end

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_issue_board, group)
  end
end

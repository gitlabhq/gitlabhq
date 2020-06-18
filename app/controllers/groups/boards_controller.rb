# frozen_string_literal: true

class Groups::BoardsController < Groups::ApplicationController
  include BoardsActions
  include RecordUserLastActivity

  before_action :authorize_read_board!, only: [:index, :show]
  before_action :assign_endpoint_vars
  before_action do
    push_frontend_feature_flag(:multi_select_board, default_enabled: true)
    push_frontend_feature_flag(:sfc_issue_boards, default_enabled: true)
    push_frontend_feature_flag(:boards_with_swimlanes, group, default_enabled: false)
  end

  private

  def assign_endpoint_vars
    @boards_endpoint = group_boards_url(group)
    @namespace_path = group.to_param
    @labels_endpoint = group_labels_url(group)
  end

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_board, group)
  end
end

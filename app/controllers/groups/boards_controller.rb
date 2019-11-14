# frozen_string_literal: true

class Groups::BoardsController < Groups::ApplicationController
  include BoardsActions
  include RecordUserLastActivity

  before_action :assign_endpoint_vars
  before_action do
    push_frontend_feature_flag(:multi_select_board, default_enabled: true)
  end

  private

  def assign_endpoint_vars
    @boards_endpoint = group_boards_url(group)
    @namespace_path = group.to_param
    @labels_endpoint = group_labels_url(group)
  end
end

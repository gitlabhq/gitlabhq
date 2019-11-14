# frozen_string_literal: true

class Projects::BoardsController < Projects::ApplicationController
  include MultipleBoardsActions
  include IssuableCollections

  before_action :check_issues_available!
  before_action :authorize_read_board!, only: [:index, :show]
  before_action :assign_endpoint_vars
  before_action do
    push_frontend_feature_flag(:multi_select_board, default_enabled: true)
  end

  private

  def assign_endpoint_vars
    @boards_endpoint = project_boards_path(project)
    @bulk_issues_path = bulk_update_project_issues_path(project)
    @namespace_path = project.namespace.full_path
    @labels_endpoint = project_labels_path(project)
  end

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_board, project)
  end
end

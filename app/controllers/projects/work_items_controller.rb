# frozen_string_literal: true

class Projects::WorkItemsController < Projects::ApplicationController
  before_action do
    push_force_frontend_feature_flag(:work_items, project&.work_items_feature_flag_enabled?)
  end

  feature_category :team_planning

  def index
    render_404 unless project&.work_items_feature_flag_enabled?
  end
end

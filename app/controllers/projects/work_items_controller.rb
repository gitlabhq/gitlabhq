# frozen_string_literal: true

class Projects::WorkItemsController < Projects::ApplicationController
  before_action do
    push_force_frontend_feature_flag(:work_items, project&.work_items_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_mvc_2, project&.work_items_mvc_2_feature_flag_enabled?)
    push_frontend_feature_flag(:work_items_hierarchy, project)
  end

  feature_category :team_planning
  urgency :low

  def index
    render_404 unless project&.work_items_feature_flag_enabled?
  end
end

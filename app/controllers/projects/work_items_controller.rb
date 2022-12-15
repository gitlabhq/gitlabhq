# frozen_string_literal: true

class Projects::WorkItemsController < Projects::ApplicationController
  before_action do
    push_force_frontend_feature_flag(:work_items, project&.work_items_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_mvc, project&.work_items_mvc_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_mvc_2, project&.work_items_mvc_2_feature_flag_enabled?)
    push_frontend_feature_flag(:use_iid_in_work_items_path, project)
  end

  feature_category :team_planning
  urgency :low
end

Projects::WorkItemsController.prepend_mod

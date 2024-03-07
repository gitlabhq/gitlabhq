# frozen_string_literal: true

module Groups
  class WorkItemsController < Groups::ApplicationController
    feature_category :team_planning

    before_action do
      push_frontend_feature_flag(:notifications_todos_buttons)
      push_force_frontend_feature_flag(:work_items, group&.work_items_feature_flag_enabled?)
      push_force_frontend_feature_flag(:work_items_beta, group&.work_items_beta_feature_flag_enabled?)
      push_force_frontend_feature_flag(:work_items_mvc_2, group&.work_items_mvc_2_feature_flag_enabled?)
      push_force_frontend_feature_flag(:linked_work_items, group&.linked_work_items_feature_flag_enabled?)
    end

    def index
      not_found unless Feature.enabled?(:namespace_level_work_items, group)
    end

    def show
      not_found unless Feature.enabled?(:namespace_level_work_items, group)
    end
  end
end

Groups::WorkItemsController.prepend_mod

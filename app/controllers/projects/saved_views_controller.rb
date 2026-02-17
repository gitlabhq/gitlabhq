# frozen_string_literal: true

module Projects
  class SavedViewsController < Projects::ApplicationController
    before_action :authenticate_user!

    feature_category :portfolio_management

    before_action do
      push_frontend_feature_flag(:notifications_todos_buttons, current_user)
      push_force_frontend_feature_flag(:glql_load_on_click, !!project&.glql_load_on_click_feature_flag_enabled?)
      push_force_frontend_feature_flag(:work_item_planning_view,
        !!project&.work_items_consolidated_list_enabled?(current_user))
      push_force_frontend_feature_flag(:use_work_item_url, !!project&.use_work_item_url?)
      push_force_frontend_feature_flag(:work_item_features_field,
        Feature.enabled?(:work_item_features_field, current_user))
    end

    def show
      return not_found unless project.work_items_saved_views_enabled?(current_user)

      render 'projects/work_items/index'
    end
  end
end

# frozen_string_literal: true

module Groups
  class SavedViewsController < Groups::ApplicationController
    before_action :authenticate_user!

    feature_category :portfolio_management

    before_action do
      push_frontend_feature_flag(:notifications_todos_buttons, current_user)
      push_force_frontend_feature_flag(:glql_load_on_click, !!group&.glql_load_on_click_feature_flag_enabled?)
      push_force_frontend_feature_flag(:use_work_item_url, !!group&.use_work_item_url?)
      push_force_frontend_feature_flag(:work_item_features_field,
        Feature.enabled?(:work_item_features_field, current_user))
      push_frontend_feature_flag(:vue3_migrate_work_items, current_user)
      push_frontend_feature_flag(:work_item_rest_api_frontend_users, current_user)
      push_frontend_feature_flag(:work_item_rest_api, current_user)
      push_frontend_feature_flag(:work_item_list_display_settings_drawer, current_user)
    end

    def show
      render 'groups/work_items/index'
    end
  end
end

Groups::SavedViewsController.prepend_mod

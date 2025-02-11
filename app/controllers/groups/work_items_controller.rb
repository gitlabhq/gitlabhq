# frozen_string_literal: true

module Groups
  class WorkItemsController < Groups::ApplicationController
    feature_category :team_planning

    before_action do
      push_frontend_feature_flag(:notifications_todos_buttons)
      push_force_frontend_feature_flag(:work_items, group&.work_items_feature_flag_enabled?)
      push_force_frontend_feature_flag(:work_items_beta, group&.work_items_beta_feature_flag_enabled?)
      push_force_frontend_feature_flag(:work_items_alpha, group&.work_items_alpha_feature_flag_enabled?)
      push_force_frontend_feature_flag(:namespace_level_work_items, namespace_work_items_enabled?)
      push_force_frontend_feature_flag(:create_group_level_work_items,
        group&.create_group_level_work_items_feature_flag_enabled?)
      push_force_frontend_feature_flag(:glql_integration, group&.glql_integration_feature_flag_enabled?)
      push_force_frontend_feature_flag(:continue_indented_text, group&.continue_indented_text_feature_flag_enabled?)
      push_frontend_feature_flag(:issues_list_drawer, group)
      push_frontend_feature_flag(:work_item_description_templates, group)
    end
    before_action :handle_new_work_item_path, only: [:show]

    def index
      not_found unless namespace_work_items_enabled?
    end

    def show
      not_found unless namespace_work_items_enabled?

      @work_item = ::WorkItems::WorkItemsFinder.new(current_user, group_id: group.id)
        .execute.with_work_item_type.find_by_iid(show_params[:iid])
    end

    private

    def namespace_work_items_enabled?
      group&.namespace_work_items_enabled?
    end

    # The work_items/:iid route renders a Vue app that takes care of the show and new pages.
    def handle_new_work_item_path
      return unless show_params[:iid] == 'new'

      if namespace_work_items_enabled?
        render :show
      else
        not_found
      end
    end

    def show_params
      params.permit(:iid)
    end
  end
end

Groups::WorkItemsController.prepend_mod

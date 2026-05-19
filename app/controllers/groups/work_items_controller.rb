# frozen_string_literal: true

module Groups
  class WorkItemsController < Groups::ApplicationController
    include SearchRateLimitable
    include WorkItemsCollections

    feature_category :portfolio_management, [:index, :rss, :calendar]
    feature_category :team_planning

    urgency :low, [:rss, :calendar]

    before_action do
      push_frontend_feature_flag(:notifications_todos_buttons, current_user)
      push_force_frontend_feature_flag(:glql_load_on_click, !!group&.glql_load_on_click_feature_flag_enabled?)
      push_force_frontend_feature_flag(:use_work_item_url, !!group&.use_work_item_url?)
      push_force_frontend_feature_flag(:work_item_features_field,
        Feature.enabled?(:work_item_features_field, current_user))
      push_frontend_feature_flag(:duo_quick_action_work_item_list, current_user)
      push_frontend_feature_flag(:vue3_migrate_work_items, current_user)
      push_frontend_feature_flag(:work_item_rest_api_frontend_users, current_user)
      push_frontend_feature_flag(:work_item_rest_api, current_user)
      push_frontend_feature_flag(:work_item_list_display_settings_drawer, current_user)
    end

    before_action :handle_new_work_item_path, only: [:show]
    before_action :check_search_rate_limit!, if: ->(c) do
      c.action_name.to_sym == :rss
    end

    prepend_before_action(only: [:calendar]) { authenticate_sessionless_user!(:ics) }
    prepend_before_action(only: [:rss]) { authenticate_sessionless_user!(:rss) }

    def index; end

    def show
      not_found unless group.supports_work_items?

      @work_item = ::WorkItems::WorkItemsFinder.new(current_user, group_id: group.id)
        .execute.find_by_iid(show_params[:iid])
    end

    def rss
      respond_to do |format|
        format.atom do
          @work_items = work_items_for_rss.non_archived

          render layout: 'xml'
        end
      end
    end

    def calendar
      @work_items = work_items_for_calendar

      respond_to do |format|
        format.ics do
          response.headers['Content-Type'] = 'text/plain' if request.referer&.start_with?(::Settings.gitlab.base_url)
        end
      end
    end

    private

    # The work_items/:iid route renders a Vue app that takes care of the show and new pages.
    def handle_new_work_item_path
      return unless show_params[:iid] == 'new'

      authenticate_user!

      render :show
    end

    def show_params
      params.permit(:iid)
    end
  end
end

Groups::WorkItemsController.prepend_mod

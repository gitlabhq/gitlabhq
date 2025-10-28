# frozen_string_literal: true

module Groups
  class WorkItemsController < Groups::ApplicationController
    include SearchRateLimitable
    include WorkItemsCollections

    feature_category :team_planning

    before_action do
      push_frontend_feature_flag(:notifications_todos_buttons, current_user)
      push_force_frontend_feature_flag(:work_items_beta, !!group&.work_items_beta_feature_flag_enabled?)
      push_force_frontend_feature_flag(:work_items_alpha, !!group&.work_items_alpha_feature_flag_enabled?)
      push_force_frontend_feature_flag(:create_group_level_work_items,
        !!group&.create_group_level_work_items_feature_flag_enabled?)
      push_force_frontend_feature_flag(:glql_load_on_click, !!group&.glql_load_on_click_feature_flag_enabled?)
      push_force_frontend_feature_flag(:work_item_planning_view, !!group&.work_items_consolidated_list_enabled?)
    end

    before_action :handle_new_work_item_path, only: [:show]
    before_action :check_search_rate_limit!, if: ->(c) do
      c.action_name.to_sym == :rss
    end

    prepend_before_action(only: [:calendar]) { authenticate_sessionless_user!(:ics) }
    prepend_before_action(only: [:rss]) { authenticate_sessionless_user!(:rss) }

    urgency :low, [:rss, :calendar]

    def index
      not_found unless group&.work_items_consolidated_list_enabled?
    end

    def show
      not_found unless group.supports_group_work_items?

      @work_item = ::WorkItems::WorkItemsFinder.new(current_user, group_id: group.id)
        .execute.with_work_item_type.find_by_iid(show_params[:iid])
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

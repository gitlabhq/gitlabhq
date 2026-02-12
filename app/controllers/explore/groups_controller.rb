# frozen_string_literal: true

class Explore::GroupsController < Explore::ApplicationController
  include GroupTree

  feature_category :groups_and_projects
  urgency :low

  MAX_QUERY_SIZE = 10_000

  def index
    respond_to do |format|
      format.html do
        @explore_groups_vue_enabled = Feature.enabled?(:explore_groups_vue, current_user)

        if @explore_groups_vue_enabled
          push_force_frontend_feature_flag(:explore_groups_vue, true)
          next render :index
        end

        render_groups
      end
      format.json { render_groups }
    end
  end

  private

  def render_groups
    finder_params = { active: safe_params[:active] }

    if Feature.enabled?(:explore_groups_non_members_only, current_user)
      finder_params[:visibility] = Gitlab::VisibilityLevel.levels_for_user(current_user)
    end

    render_group_tree GroupsFinder.new(current_user, finder_params).execute.limit(MAX_QUERY_SIZE)
  end
end

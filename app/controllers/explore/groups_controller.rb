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
    render_group_tree GroupsFinder.new(current_user, active: safe_params[:active]).execute.limit(MAX_QUERY_SIZE)
  end
end

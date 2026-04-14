# frozen_string_literal: true

class Explore::GroupsController < Explore::ApplicationController
  include GroupTree

  feature_category :groups_and_projects
  urgency :low

  MAX_QUERY_SIZE = 10_000

  def index
    respond_to do |format|
      format.html { render :index }
      format.json { render_groups }
    end
  end

  private

  def render_groups
    finder_params = {
      active: safe_params[:active],
      visibility: Gitlab::VisibilityLevel.levels_for_user(current_user)
    }

    render_group_tree GroupsFinder.new(current_user, finder_params).execute.limit(MAX_QUERY_SIZE)
  end
end

Explore::GroupsController.prepend_mod_with('Explore::GroupsController')

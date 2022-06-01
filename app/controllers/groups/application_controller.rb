# frozen_string_literal: true

class Groups::ApplicationController < ApplicationController
  include RoutableActions
  include ControllerWithCrossProjectAccessCheck
  include SortingHelper
  include SortingPreference

  layout 'group'

  skip_before_action :authenticate_user!
  before_action :group
  before_action :set_sorting
  requires_cross_project_access

  private

  def group
    @group ||= find_routable!(Group, params[:group_id] || params[:id], request.fullpath)
  end

  def group_projects
    @projects ||= GroupProjectsFinder.new(group: group, current_user: current_user).execute
  end

  def group_projects_with_subgroups
    @group_projects_with_subgroups ||= GroupProjectsFinder.new(
      group: group,
      current_user: current_user,
      options: { include_subgroups: true }
    ).execute
  end

  def authorize_admin_group!
    unless can?(current_user, :admin_group, group)
      render_404
    end
  end

  def authorize_admin_group_runners!
    unless can?(current_user, :admin_group_runners, group)
      render_404
    end
  end

  def authorize_read_group_runners!
    unless can?(current_user, :read_group_runners, group)
      render_404
    end
  end

  def authorize_create_deploy_token!
    unless can?(current_user, :create_deploy_token, group)
      render_404
    end
  end

  def authorize_destroy_deploy_token!
    unless can?(current_user, :destroy_deploy_token, group)
      render_404
    end
  end

  def authorize_admin_group_member!
    unless can?(current_user, :admin_group_member, group)
      render_403
    end
  end

  def authorize_read_group_member!
    unless can?(current_user, :read_group_member, group)
      render_403
    end
  end

  def build_canonical_path(group)
    params[:group_id] = group.to_param

    url_for(safe_params)
  end

  def set_sorting
    if has_project_list?
      @group_projects_sort = set_sort_order(Project::SORTING_PREFERENCE_FIELD, sort_value_name)
    end
  end

  def has_project_list?
    false
  end

  def validate_root_group!
    render_404 unless group.root?
  end
end

Groups::ApplicationController.prepend_mod_with('Groups::ApplicationController')

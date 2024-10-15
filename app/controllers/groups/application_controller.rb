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

  before_action do
    push_namespace_setting(:math_rendering_limits_enabled, @group)
  end

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
    render_404 unless can?(current_user, :admin_group, group)
  end

  def authorize_create_deploy_token!
    render_404 unless can?(current_user, :create_deploy_token, group)
  end

  def authorize_destroy_deploy_token!
    render_404 unless can?(current_user, :destroy_deploy_token, group)
  end

  def authorize_admin_group_member!
    render_403 unless can?(current_user, :admin_group_member, group)
  end

  def authorize_owner_access!
    render_403 unless can?(current_user, :owner_access, group)
  end

  def authorize_billings_page!
    render_404 unless can?(current_user, :read_billing, group)
  end

  def authorize_read_group_member!
    render_403 unless can?(current_user, :read_group_member, group)
  end

  def build_canonical_path(group)
    params[:group_id] = group.to_param

    url_for(safe_params)
  end

  def set_sorting
    @group_projects_sort = set_sort_order(Project::SORTING_PREFERENCE_FIELD, sort_value_name) if has_project_list?
  end

  def has_project_list?
    false
  end

  def validate_crm_group!
    render_404 unless group.crm_group?
  end

  def authorize_action!(action)
    access_denied! unless can?(current_user, action, group)
  end

  def respond_to_missing?(method, *args)
    case method.to_s
    when /\Aauthorize_(.*)!\z/
      true
    else
      super
    end
  end

  def method_missing(method_sym, *arguments, &block)
    case method_sym.to_s
    when /\Aauthorize_(.*)!\z/
      authorize_action!(Regexp.last_match(1).to_sym)
    else
      super
    end
  end
end

Groups::ApplicationController.prepend_mod_with('Groups::ApplicationController')

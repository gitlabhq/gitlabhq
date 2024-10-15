# frozen_string_literal: true

class Projects::ProjectMembersController < Projects::ApplicationController
  include MembershipActions
  include MembersPresentation
  include SortingHelper

  # Authorize
  before_action :authorize_admin_project_member!, except: [:index, :leave, :request_access]

  feature_category :groups_and_projects
  urgency :low

  def index
    @sort = pagination_params[:sort].presence || sort_value_name
    @include_relations ||= requested_relations(:groups_with_inherited_permissions)

    if can?(current_user, :admin_project_member, @project)
      @invited_members = present_members(invited_members)
      @requesters = present_members(AccessRequestsFinder.new(@project).execute(current_user))
    end

    @project_members = present_members(non_invited_members.page(pagination_params[:page]))
  end

  # MembershipActions concern
  alias_method :membershipable, :project

  private

  def members
    @members ||= MembersFinder
      .new(@project, current_user, params: filter_params)
      .execute(include_relations: requested_relations)
  end

  def invited_members
    members.invite.with_invited_user_state
  end

  def non_invited_members
    members.non_invite
  end

  def filter_params
    params.permit(:search, :max_role).merge(sort: @sort)
  end

  def membershipable_members
    project.namespace_members
  end

  def plain_source_type
    'project'
  end

  def source_type
    _("project")
  end

  def source
    project
  end

  def members_page_url
    project_project_members_path(project)
  end

  def root_params_key
    :project_member
  end

  def members_and_requesters
    project.namespace_members_and_requesters
  end

  def requesters
    project.namespace_requesters
  end
end

Projects::ProjectMembersController.prepend_mod_with('Projects::ProjectMembersController')

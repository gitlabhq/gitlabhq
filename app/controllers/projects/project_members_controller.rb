# frozen_string_literal: true

class Projects::ProjectMembersController < Projects::ApplicationController
  include MembershipActions
  include Members::InviteModalActions
  include MembersPresentation
  include SortingHelper

  # Authorize
  before_action :authorize_admin_project_member!, except: [:index, :leave, :request_access]

  feature_category :groups_and_projects
  urgency :low

  def index
    @sort = pagination_params[:sort].presence || sort_value_name
    @include_relations ||= requested_relations(:groups_with_inherited_permissions)

    @group_member_links = group_member_links

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

  def group_member_links
    paginator = Gitlab::MultiCollectionPaginator.new(project_group_links, group_group_links)
    result = paginator.paginate(pagination_params[:page])

    Members::GroupLinksCollection.new(
      result,
      page: pagination_params[:page].to_i,
      total_count: paginator.total_count
    )
  end

  def project_group_links
    return ::ProjectGroupLink.none unless @include_relations.include?(:direct)

    ::Projects::ProjectGroupLinksFinder.new(@project, { max_access: true, search: search_groups }).execute
  end

  def group_group_links
    return ::GroupGroupLink.none unless @include_relations.include?(:inherited)

    ::Projects::GroupGroupLinksFinder.new(@project, { max_access: true, search: search_groups }).execute
  end

  def filter_params
    params.permit(:search, :max_role).merge(sort: @sort)
  end

  def group_filter_params
    params.permit(:search_groups)
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

  def search_groups
    group_filter_params[:search_groups]
  end
end

Projects::ProjectMembersController.prepend_mod_with('Projects::ProjectMembersController')

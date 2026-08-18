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

    respond_to do |format|
      format.html { index_html }
      # The Direct members tab fetches from this action rather than the public
      # `GET /projects/:id/members` API because the members app consumes the
      # internal `MemberSerializer`/`MemberEntity` shape (`can_update`,
      # `can_remove`, `is_direct_member`, the `access_level` object, role
      # metadata) that the public `Entities::Member` contract does not expose,
      # and it rides the same members-page authorization and pagination.
      format.json { render json: direct_members_list_data }
    end
  end

  # MembershipActions concern
  alias_method :membershipable, :project

  private

  def index_html
    @include_relations ||= requested_relations(:groups_with_inherited_permissions)

    @group_member_links = group_member_links

    if can?(current_user, :admin_project_member, @project)
      @invited_members = present_members(invited_members)
      @requesters = present_members(AccessRequestsFinder.new(@project).execute(current_user))
    end

    @project_members = present_members(non_invited_members.page(pagination_params[:page]))
  end

  def direct_members_list_data
    direct_members = present_members(non_invited_direct_members.page(direct_members_page))

    ::Projects::ProjectMembers::AppDataSerializer
      .new(@project, current_user: current_user)
      .list_data(direct_members, { param_name: :direct_members_page, params: { search_groups: nil } })
  end

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

  def direct_members_page
    params.permit(:direct_members_page)[:direct_members_page]
  end

  def direct_members
    MembersFinder
      .new(@project, current_user, params: direct_member_filter_params)
      .execute(include_relations: [:direct])
  end

  def non_invited_direct_members
    direct_members.non_invite
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

  def direct_member_filter_params
    permitted = params.permit(:search_direct_members, :max_role)

    { search: permitted[:search_direct_members], max_role: permitted[:max_role], sort: @sort }
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

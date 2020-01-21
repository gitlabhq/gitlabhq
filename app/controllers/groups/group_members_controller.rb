# frozen_string_literal: true

class Groups::GroupMembersController < Groups::ApplicationController
  include MembershipActions
  include MembersPresentation
  include SortingHelper

  MEMBER_PER_PAGE_LIMIT = 50

  def self.admin_not_required_endpoints
    %i[index leave request_access]
  end

  # Authorize
  before_action :authorize_admin_group_member!, except: admin_not_required_endpoints

  skip_before_action :check_two_factor_requirement, only: :leave
  skip_cross_project_access_check :index, :create, :update, :destroy, :request_access,
                                  :approve_access_request, :leave, :resend_invite,
                                  :override

  def index
    @sort = params[:sort].presence || sort_value_name
    @project = @group.projects.find(params[:project_id]) if params[:project_id]
    @members = find_members

    if can_manage_members
      @skip_groups = @group.related_group_ids
      @invited_members = present_invited_members(@members)
    end

    @members = @members.non_invite
    @members = present_group_members(@members)

    @requesters = present_members(
      AccessRequestsFinder.new(@group).execute(current_user))

    @group_member = @group.group_members.new
  end

  # MembershipActions concern
  alias_method :membershipable, :group

  private

  def present_invited_members(members)
    invited_members = members.invite

    if params[:search_invited].present?
      invited_members = invited_members.search_invite_email(params[:search_invited])
    end

    present_members(invited_members
          .page(params[:invited_members_page])
          .per(MEMBER_PER_PAGE_LIMIT))
  end

  def find_members
    filter_params = params.slice(:two_factor, :search).merge(sort: @sort)
    GroupMembersFinder.new(@group, current_user).execute(include_relations: requested_relations, params: filter_params)
  end

  def can_manage_members
    can?(current_user, :admin_group_member, @group)
  end

  def present_group_members(original_members)
    members = original_members.page(params[:page]).per(MEMBER_PER_PAGE_LIMIT)
    present_members(members)
  end
end

Groups::GroupMembersController.prepend_if_ee('EE::Groups::GroupMembersController')

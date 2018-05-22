class Groups::GroupMembersController < Groups::ApplicationController
  prepend EE::Groups::GroupMembersController

  include MembershipActions
  include MembersPresentation
  include SortingHelper

  def self.admin_not_required_endpoints
    %i[index leave request_access]
  end

  # Authorize
  before_action :authorize_admin_group_member!, except: admin_not_required_endpoints

  skip_cross_project_access_check :index, :create, :update, :destroy, :request_access,
                                  :approve_access_request, :leave, :resend_invite,
                                  :override

  def index
    can_manage_members = can?(current_user, :admin_group_member, @group)

    @sort = params[:sort].presence || sort_value_name
    @project = @group.projects.find(params[:project_id]) if params[:project_id]

    @members = GroupMembersFinder.new(@group).execute
    @members = @members.non_invite unless can_manage_members
    @members = @members.search(params[:search]) if params[:search].present?
    @members = @members.sort_by_attribute(@sort)

    if can_manage_members && params[:two_factor].present?
      @members = @members.filter_by_2fa(params[:two_factor])
    end

    @members = @members.page(params[:page]).per(50)
    @members = present_members(@members.includes(:user))

    @requesters = present_members(
      AccessRequestsFinder.new(@group).execute(current_user))

    @group_member = @group.group_members.new
  end

  # MembershipActions concern
  alias_method :membershipable, :group
end

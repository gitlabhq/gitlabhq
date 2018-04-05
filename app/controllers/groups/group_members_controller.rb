class Groups::GroupMembersController < Groups::ApplicationController
  include MembershipActions
  include MembersPresentation
  include SortingHelper

  # Authorize
  before_action :authorize_admin_group_member!, except: [:index, :leave, :request_access]

  skip_cross_project_access_check :index, :create, :update, :destroy, :request_access,
                                  :approve_access_request, :leave, :resend_invite,
                                  :override

  def index
    @sort = params[:sort].presence || sort_value_name
    @project = @group.projects.find(params[:project_id]) if params[:project_id]

    @members = GroupMembersFinder.new(@group).execute
    @members = @members.non_invite unless can?(current_user, :admin_group, @group)
    @members = @members.search(params[:search]) if params[:search].present?
    @members = @members.sort_by_attribute(@sort)
    @members = @members.page(params[:page]).per(50)
    @members = present_members(@members.includes(:user))

    @requesters = present_members(
      AccessRequestsFinder.new(@group).execute(current_user))

    @group_member = @group.group_members.new
  end

  # MembershipActions concern
  alias_method :membershipable, :group
end

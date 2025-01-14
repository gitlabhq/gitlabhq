# frozen_string_literal: true

class Groups::GroupMembersController < Groups::ApplicationController
  include MembershipActions
  include MembersPresentation
  include SortingHelper
  include Gitlab::Utils::StrongMemoize

  MEMBER_PER_PAGE_LIMIT = 50

  def self.admin_not_required_endpoints
    %i[index leave request_access]
  end

  # Authorize
  before_action :authorize_admin_group_member!, except: admin_not_required_endpoints
  before_action :authorize_read_group_member!, only: :index

  before_action only: [:index] do
    push_frontend_feature_flag(:importer_user_mapping, current_user)
    push_frontend_feature_flag(:importer_user_mapping_reassignment_csv, current_user)
    push_frontend_feature_flag(:service_accounts_crud, @group)
  end

  skip_before_action :check_two_factor_requirement, only: :leave
  skip_cross_project_access_check :index, :update, :destroy, :request_access,
    :approve_access_request, :leave, :resend_invite, :override

  feature_category :groups_and_projects
  urgency :low

  def index
    @sort = params[:sort].presence || sort_value_name
    @include_relations ||= requested_relations(:groups_with_inherited_permissions)

    if can?(current_user, :admin_group_member, @group)
      @invited_members = invited_members

      if params[:search_invited].present?
        @invited_members = @invited_members.search_invite_email(params[:search_invited])
      end

      @invited_members = present_invited_members(@invited_members)
    end

    @members = present_group_members(non_invited_members)
    @placeholder_users_count = placeholder_users_count

    @requesters = present_members(
      AccessRequestsFinder.new(@group).execute(current_user)
    )
  end

  # MembershipActions concern
  alias_method :membershipable, :group

  private

  def members
    @members ||= GroupMembersFinder
      .new(@group, current_user, params: filter_params)
      .execute(include_relations: requested_relations)
  end

  def invited_members
    members.invite.with_invited_user_state
  end

  def non_invited_members
    members.non_invite
  end

  def present_invited_members(invited_members)
    present_members(invited_members
      .page(params[:invited_members_page])
      .per(MEMBER_PER_PAGE_LIMIT))
  end

  def present_group_members(members)
    present_members(members
      .page(params[:page])
      .per(MEMBER_PER_PAGE_LIMIT))
  end

  def filter_params
    params.permit(:two_factor, :search, :user_type, :max_role).merge(sort: @sort)
  end

  def membershipable_members
    group.members
  end

  def plain_source_type
    'group'
  end

  def source_type
    _("group")
  end

  def source
    group
  end

  def members_page_url
    polymorphic_url([group, :members])
  end

  def root_params_key
    :group_member
  end

  def placeholder_users_count
    {
      pagination: {
        total_items: placeholder_users.count,
        awaiting_reassignment_items: placeholder_users.awaiting_reassignment.count,
        reassigned_items: placeholder_users.reassigned.count
      }
    }
  end

  def placeholder_users
    if Feature.enabled?(:importer_user_mapping, current_user)
      Import::SourceUsersFinder.new(@group, current_user).execute
    else
      Import::SourceUser.none
    end
  end
  strong_memoize_attr :placeholder_users
end

Groups::GroupMembersController.prepend_mod_with('Groups::GroupMembersController')

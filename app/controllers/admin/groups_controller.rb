# frozen_string_literal: true

class Admin::GroupsController < Admin::ApplicationController
  include MembersPresentation

  before_action :group, only: [:edit, :update, :destroy, :project_update, :members_update]

  feature_category :groups_and_projects, [:create, :destroy, :edit, :index, :members_update, :new, :show, :update]

  def index
    @groups = groups.sort_by_attribute(@sort = pagination_params[:sort])
    @groups = @groups.search(safe_params[:name]) if safe_params[:name].present?
    @groups = @groups.page(pagination_params[:page])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    # Group.with_statistics doesn't behave nicely when including other relations.
    # Group.find_by_full_path includes the routes relation to avoid a common N+1
    # (at the expense of this action: there are two queries here to find and retrieve
    # the Group with statistics).
    @group = Group.with_statistics.find(group&.id)
    @members = present_members(
      group_members.order("access_level DESC").page(safe_params[:members_page]))
    @requesters = present_members(
      AccessRequestsFinder.new(@group).execute(current_user))
    @projects = @group.projects.with_statistics.page(safe_params[:projects_page])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def new
    @group = Group.new
    @group.build_admin_note
  end

  def edit
    @group.build_admin_note unless @group.admin_note
  end

  def create
    response = ::Groups::CreateService.new(current_user,
      group_params.with_defaults(organization_id: Current.organization_id)).execute
    @group = response[:group]

    if response.success?
      redirect_to [:admin, @group],
        notice: format(_('Group %{group_name} was successfully created.'), group_name: @group.name)
    else
      render "new"
    end
  end

  def update
    @group.build_admin_note unless @group.admin_note

    if Groups::UpdateService.new(@group, current_user, group_params).execute
      unless Gitlab::Utils.to_boolean(group_params['runner_registration_enabled'])
        Ci::Runners::ResetRegistrationTokenService.new(@group, current_user).execute
      end

      redirect_to [:admin, @group], notice: _('Group was successfully updated.')
    else
      render "edit"
    end
  end

  def destroy
    Groups::DestroyService.new(@group, current_user).async_execute

    flash[:toast] = format(_("Group '%{group_name}' is being deleted."), group_name: @group.full_name)

    redirect_to admin_groups_path, status: :found
  end

  private

  def groups
    Group.with_statistics.with_route
  end

  def group
    @group ||= Group.find_by_full_path(params.permit(:id)[:id])
  end

  def group_members
    @group.members
  end

  def group_params
    params.require(:group).permit(allowed_group_params)
  end

  def allowed_group_params
    [
      :avatar,
      :description,
      :lfs_enabled,
      :name,
      :path,
      :request_access_enabled,
      :runner_registration_enabled,
      :visibility_level,
      :require_two_factor_authentication,
      :two_factor_grace_period,
      :enabled_git_access_protocol,
      :project_creation_level,
      :subgroup_creation_level,
      :organization_id,
      { admin_note_attributes: [
        :note
      ] }
    ]
  end

  def safe_params
    params.permit(:name, :members_page, :projects_page)
  end
end

Admin::GroupsController.prepend_mod_with('Admin::GroupsController')

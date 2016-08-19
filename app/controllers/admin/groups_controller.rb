class Admin::GroupsController < Admin::ApplicationController
  before_action :group, only: [:edit, :show, :update, :destroy, :project_update, :members_update]

  def index
    @groups = Group.all
    @groups = @groups.sort(@sort = params[:sort])
    @groups = @groups.search(params[:name]) if params[:name].present?
    @groups = @groups.page(params[:page])
  end

  def show
    @members = @group.members.order("access_level DESC").page(params[:members_page])
    @requesters = @group.requesters
    @projects = @group.projects.page(params[:projects_page])
  end

  def new
    @group = Group.new
  end

  def edit
  end

  def create
    @group = Group.new(group_params)
    @group.name = @group.path.dup unless @group.name

    if @group.save
      @group.add_owner(current_user)
      redirect_to [:admin, @group], notice: 'Group was successfully created.'
    else
      render "new"
    end
  end

  def update
    if @group.update_attributes(group_params)
      redirect_to [:admin, @group], notice: 'Group was successfully updated.'
    else
      render "edit"
    end
  end

  def members_update
    @group.add_users(params[:user_ids].split(','), params[:access_level], current_user)

    redirect_to [:admin, @group], notice: 'Users were successfully added.'
  end

  def destroy
    DestroyGroupService.new(@group, current_user).async_execute

    redirect_to admin_groups_path, alert: "Group '#{@group.name}' was scheduled for deletion."
  end

  private

  def group
    @group ||= Group.find_by(path: params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :description, :path, :avatar, :visibility_level, :request_access_enabled)
  end
end

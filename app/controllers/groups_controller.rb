class GroupsController < Groups::ApplicationController
  include IssuesAction
  include MergeRequestsAction
  include ParamsBackwardCompatibility
  include PreviewMarkdown

  respond_to :html

  before_action :authenticate_user!, only: [:new, :create]
  before_action :group, except: [:index, :new, :create]

  # Authorize
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy, :projects, :transfer]
  before_action :authorize_create_group!, only: [:new]

  before_action :group_projects, only: [:projects, :activity, :issues, :merge_requests]
  before_action :event_filter, only: [:activity]

  before_action :user_actions, only: [:show, :subgroups]

  skip_cross_project_access_check :index, :new, :create, :edit, :update,
                                  :destroy, :projects
  # When loading show as an atom feed, we render events that could leak cross
  # project information
  skip_cross_project_access_check :show, if: -> { request.format.html? }

  layout :determine_layout

  def index
    redirect_to(current_user ? dashboard_groups_path : explore_groups_path)
  end

  def new
    @group = Group.new(params.permit(:parent_id))
  end

  def create
    @group = Groups::CreateService.new(current_user, group_params).execute

    if @group.persisted?
      notice = if @group.chat_team.present?
                 "Group '#{@group.name}' and its Mattermost team were successfully created."
               else
                 "Group '#{@group.name}' was successfully created."
               end

      redirect_to @group, notice: notice
    else
      render action: "new"
    end
  end

  def show
    respond_to do |format|
      format.html do
        @has_children = GroupDescendantsFinder.new(current_user: current_user,
                                                   parent_group: @group,
                                                   params: params).has_children?
      end

      format.atom do
        load_events
        render layout: 'xml.atom'
      end
    end
  end

  def activity
    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end
    end
  end

  def edit
  end

  def projects
    @projects = @group.projects.with_statistics.page(params[:page])
  end

  def update
    if Groups::UpdateService.new(@group, current_user, group_params).execute
      redirect_to edit_group_path(@group), notice: "Group '#{@group.name}' was successfully updated."
    else
      @group.restore_path!

      render action: "edit"
    end
  end

  def destroy
    Groups::DestroyService.new(@group, current_user).async_execute

    redirect_to root_path, status: 302, alert: "Group '#{@group.name}' was scheduled for deletion."
  end

  def transfer
    parent_group = Group.find_by(id: params[:new_parent_group_id])
    service = ::Groups::TransferService.new(@group, current_user)

    if service.execute(parent_group)
      flash[:notice] = "Group '#{@group.name}' was successfully transferred."
      redirect_to group_path(@group)
    else
      flash.now[:alert] = service.error
      render :edit
    end
  end

  protected

  def authorize_create_group!
    allowed = if params[:parent_id].present?
                parent = Group.find_by(id: params[:parent_id])
                can?(current_user, :create_subgroup, parent)
              else
                can?(current_user, :create_group)
              end

    render_404 unless allowed
  end

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'application'
    elsif [:edit, :update, :projects].include?(action_name.to_sym)
      'group_settings'
    else
      'group'
    end
  end

  def group_params
    params.require(:group).permit(group_params_attributes)
  end

  def group_params_attributes
    [
      :avatar,
      :description,
      :lfs_enabled,
      :name,
      :path,
      :public,
      :request_access_enabled,
      :share_with_group_lock,
      :visibility_level,
      :parent_id,
      :create_chat_team,
      :chat_team_name,
      :require_two_factor_authentication,
      :two_factor_grace_period
    ]
  end

  def load_events
    params[:sort] ||= 'latest_activity_desc'

    options = {}
    options[:only_owned] = true if params[:shared] == '0'
    options[:only_shared] = true if params[:shared] == '1'

    @projects = GroupProjectsFinder.new(params: params, group: group, options: options, current_user: current_user)
                  .execute
                  .includes(:namespace)

    @events = EventCollection
      .new(@projects, offset: params[:offset].to_i, filter: event_filter)
      .to_a

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end

  def user_actions
    if current_user
      @notification_setting = current_user.notification_settings_for(group)
    end
  end

  def build_canonical_path(group)
    return group_path(group) if action_name == 'show' # root group path

    params[:id] = group.to_param

    url_for(params)
  end
end

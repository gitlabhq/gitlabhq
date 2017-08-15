class GroupsController < Groups::ApplicationController
  include IssuesAction
  include MergeRequestsAction
  include ParamsBackwardCompatibility

  respond_to :html

  before_action :authenticate_user!, only: [:new, :create]
  before_action :group, except: [:index, :new, :create]

  # Authorize
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy, :projects]
  before_action :authorize_create_group!, only: [:new, :create]

  before_action :group_projects, only: [:projects, :activity, :issues, :merge_requests]
  before_action :group_merge_requests, only: [:merge_requests]
  before_action :event_filter, only: [:activity]

  before_action :user_actions, only: [:show, :subgroups]

  layout :determine_layout

  def index
    redirect_to(current_user ? dashboard_groups_path : explore_groups_path)
  end

  def new
    @group = Group.new
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
    setup_projects

    respond_to do |format|
      format.html

      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", locals: { projects: @projects })
        }
      end

      format.atom do
        load_events
        render layout: 'xml.atom'
      end
    end
  end

  def subgroups
    return not_found unless Group.supports_nested_groups?

    @nested_groups = GroupsFinder.new(current_user, parent: group).execute
    @nested_groups = @nested_groups.search(params[:filter_groups]) if params[:filter_groups].present?
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

  protected

  def setup_projects
    set_non_archived_param
    params[:sort] ||= 'latest_activity_desc'
    @sort = params[:sort]

    options = {}
    options[:only_owned] = true if params[:shared] == '0'
    options[:only_shared] = true if params[:shared] == '1'

    @projects = GroupProjectsFinder.new(params: params, group: group, options: options, current_user: current_user).execute
    @projects = @projects.includes(:namespace)
    @projects = @projects.page(params[:page]) if params[:name].blank?
  end

  def authorize_create_group!
    unless can?(current_user, :create_group)
      return render_404
    end
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
    params.require(:group).permit(group_params_ce << group_params_ee)
  end

  def group_params_ce
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

  def group_params_ee
    [
      :membership_lock,
      :repository_size_limit
    ]
  end

  def load_events
    @events = EventCollection
      .new(@projects, offset: params[:offset].to_i, filter: event_filter)
      .to_a
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

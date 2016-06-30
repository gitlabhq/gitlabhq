class GroupsController < Groups::ApplicationController
  include FilterProjects
  include IssuesAction
  include MergeRequestsAction

  respond_to :html

  before_action :authenticate_user!, only: [:new, :create]
  before_action :group, except: [:index, :new, :create, :autocomplete]

  # Authorize
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy, :projects]
  before_action :authorize_create_group!, only: [:new, :create]

  # Load group projects
  before_action :group_projects, only: [:show, :projects, :activity, :issues, :merge_requests]
  before_action :event_filter, only: [:activity]

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
      redirect_to @group, notice: "Group '#{@group.name}' was successfully created."
    else
      render action: "new"
    end
  end

  def show
    if current_user
      @last_push            = current_user.recent_push
      @notification_setting = current_user.notification_settings_for(group)
    end

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
        render layout: false
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
    @projects = @group.projects.page(params[:page])
  end

  def update
    if Groups::UpdateService.new(@group, current_user, group_params).execute
      redirect_to edit_group_path(@group), notice: "Group '#{@group.name}' was successfully updated."
    else
      render action: "edit"
    end
  end

  def destroy
    DestroyGroupService.new(@group, current_user).execute

    redirect_to root_path, alert: "Group '#{@group.name}' was successfully deleted."
  end

  def autocomplete
    groups = Group.search(params[:search]).limit(params[:per_page])

    render json: groups.to_json
  end

  protected

  def setup_projects
    @projects = @projects.includes(:namespace)
    @projects = @projects.sorted_by_activity
    @projects = filter_projects(@projects)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.page(params[:page]) if params[:filter_projects].blank?

    @shared_projects = GroupProjectsFinder.new(group, only_shared: true).execute(current_user)
  end

  def authorize_create_group!
    unless can?(current_user, :create_group, nil)
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
    params.require(:group).permit(:name, :description, :path, :avatar, :public, :visibility_level, :share_with_group_lock, :membership_lock)
  end

  def load_events
    @events = Event.in_projects(@projects)
    @events = event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end

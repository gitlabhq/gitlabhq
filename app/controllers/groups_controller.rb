class GroupsController < Groups::ApplicationController
  include FilterProjects
  include IssuesAction
  include MergeRequestsAction

  respond_to :html

  skip_before_action :authenticate_user!, only: [:index, :show, :issues, :merge_requests]
  before_action :group, except: [:index, :new, :create]

  # Authorize
  before_action :authorize_read_group!, except: [:index, :show, :new, :create, :autocomplete]
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy, :projects]
  before_action :authorize_create_group!, only: [:new, :create]

  # Load group projects
  before_action :load_projects, except: [:index, :new, :create, :projects, :edit, :update, :autocomplete]
  before_action :event_filter, only: [:activity]

  layout :determine_layout

  def index
    redirect_to(current_user ? dashboard_groups_path : explore_groups_path)
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.name = @group.path.dup unless @group.name

    if @group.save
      @group.add_owner(current_user)
      redirect_to @group, notice: "Group '#{@group.name}' was successfully created."
    else
      render action: "new"
    end
  end

  def show
    @last_push = current_user.recent_push if current_user
    @projects = @projects.includes(:namespace)
    @projects = filter_projects(@projects)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.page(params[:page]).per(PER_PAGE) if params[:filter_projects].blank?

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
    if @group.update_attributes(group_params)
      redirect_to edit_group_path(@group), notice: "Group '#{@group.name}' was successfully updated."
    else
      render action: "edit"
    end
  end

  def destroy
    DestroyGroupService.new(@group, current_user).execute

    redirect_to root_path, alert: "Group '#{@group.name}' was successfully deleted."
  end

  protected

  def group
    @group ||= Group.find_by(path: params[:id])
    @group || render_404
  end

  def load_projects
    @projects ||= ProjectsFinder.new.execute(current_user, group: group).sorted_by_activity
  end

  # Dont allow unauthorized access to group
  def authorize_read_group!
    unless @group and (@projects.present? or can?(current_user, :read_group, @group))
      if current_user.nil?
        return authenticate_user!
      else
        return render_404
      end
    end
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
    params.require(:group).permit(:name, :description, :path, :avatar, :public)
  end

  def load_events
    @events = Event.in_projects(@projects)
    @events = event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end

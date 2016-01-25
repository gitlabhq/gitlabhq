class GroupsController < Groups::ApplicationController
  include IssuesAction
  include MergeRequestsAction
  include ProjectsListing

  skip_before_action :authenticate_user!, only: [:show, :projects, :issues, :merge_requests]
  respond_to :html
  before_action :load_group, except: [:new, :create]

  # Authorize
  before_action :authorize_read_group!, except: [:show, :projects, :new, :create, :autocomplete]
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy]
  before_action :authorize_create_group!, only: [:new, :create]

  # Load group projects
  before_action :load_projects, only: [:show, :projects, :issues, :merge_requests]
  before_action :load_contributed_projects, :load_starred_projects, only: :projects
  before_action :event_filter, only: :show

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

    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end

      format.atom do
        load_events
        render layout: false
      end
    end
  end

  def edit
  end

  def projects
    # No matter if the user is logged-in or not, @all_projects is always needed.
    @all_projects = @projects

    # When the user is logged-in, we need @all_projects, @contributed_projects
    # and, @starred_projects to display their respective projects count in the
    # UI. Depending on the current scope (none or 'all', 'contributed' or
    # 'starred'), the @projects variable will reference one of these 3 variables
    # and is used for the projects list in the page.
    if current_user
      @starred_projects = @starred_projects.in_namespace(@group.id)
      @projects = case params[:scope]
                  when 'contributed'
                    @contributed_projects
                  when 'starred'
                    @starred_projects
                  else
                    @all_projects
                  end
    end
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

  def load_group
    @group ||= Group.find_by(path: params[:id])
  end

  def load_projects
    @projects ||= prepare_for_listing(
      ProjectsFinder.new.execute(current_user, group: @group)
    )
  end

  def load_contributed_projects
    return unless current_user

    @contributed_projects ||= prepare_for_listing(
      ContributedProjectsFinder.new(current_user).execute(current_user).
        in_namespace(@group.id)
    )
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
    elsif [:edit, :update].include?(action_name.to_sym)
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

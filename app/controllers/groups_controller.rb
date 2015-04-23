class GroupsController < Groups::ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :issues, :merge_requests]
  respond_to :html
  before_action :group, except: [:new, :create]

  # Authorize
  before_action :authorize_read_group!, except: [:new, :create]
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy, :projects]
  before_action :authorize_create_group!, only: [:new, :create]

  # Load group projects
  before_action :load_projects, except: [:new, :create, :projects, :edit, :update]
  before_action :event_filter, only: :show
  before_action :set_title, only: [:new, :create]

  layout :determine_layout

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.name = @group.path.dup unless @group.name

    if @group.save
      @group.add_owner(current_user)
      redirect_to @group, notice: 'Group was successfully created.'
    else
      render action: "new"
    end
  end

  def show
    @last_push = current_user.recent_push if current_user
    @projects = @projects.includes(:namespace)

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

  def merge_requests
    @merge_requests = get_merge_requests_collection
    @merge_requests = @merge_requests.page(params[:page]).per(PER_PAGE)
    @merge_requests = @merge_requests.preload(:author, :target_project)
  end

  def issues
    @issues = get_issues_collection
    @issues = @issues.page(params[:page]).per(PER_PAGE)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def edit
  end

  def projects
    @projects = @group.projects.page(params[:page])
  end

  def update
    if @group.update_attributes(group_params)
      redirect_to edit_group_path(@group), notice: 'Group was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @group.destroy

    redirect_to root_path, notice: 'Group was removed.'
  end

  protected

  def group
    @group ||= Group.find_by(path: params[:id])
  end

  def load_projects
    @projects ||= ProjectsFinder.new.execute(current_user, group: group).sorted_by_activity.non_archived
  end

  def project_ids
    @projects.pluck(:id)
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

  def set_title
    @title = 'New Group'
  end

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'navless'
    elsif current_user
      'group'
    else
      'public_group'
    end
  end

  def group_params
    params.require(:group).permit(:name, :description, :path, :avatar)
  end

  def load_events
    @events = Event.in_projects(project_ids)
    @events = event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end

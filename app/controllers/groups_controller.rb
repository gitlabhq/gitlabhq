class GroupsController < ApplicationController
  respond_to :html
  before_filter :group, except: [:new, :create]

  # Authorize
  before_filter :authorize_read_group!, except: [:new, :create]
  before_filter :authorize_admin_group!, only: [:edit, :update, :destroy]
  before_filter :authorize_create_group!, only: [:new, :create]

  # Load group projects
  before_filter :projects, except: [:new, :create]

  before_filter :default_filter, only: [:issues, :merge_requests]

  layout :determine_layout

  before_filter :set_title, only: [:new, :create]

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(params[:group])
    @group.path = @group.name.dup.parameterize if @group.name

    if @group.save
      @group.add_owner(current_user)
      redirect_to @group, notice: 'Group was successfully created.'
    else
      render action: "new"
    end
  end

  def show
    @events = Event.in_projects(project_ids)
    @events = event_filter.apply_filter(@events)
    @events = @events.limit(20).offset(params[:offset] || 0)
    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.json { pager_json("events/_events", @events.count) }
      format.atom { render layout: false }
    end
  end

  def merge_requests
    @merge_requests = FilteringService.new.execute(MergeRequest, current_user, params)
    @merge_requests = @merge_requests.page(params[:page]).per(20)
  end

  def issues
    @issues = FilteringService.new.execute(Issue, current_user, params)
    @issues = @issues.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def members
    @project = group.projects.find(params[:project_id]) if params[:project_id]
    @members = group.users_groups

    if params[:search].present?
      users = group.users.search(params[:search])
      @members = @members.where(user_id: users)
    end

    @members = @members.order('group_access DESC').page(params[:page]).per(50)
    @users_group = UsersGroup.new
  end

  def edit
  end

  def update
    if @group.update_attributes(params[:group])
      redirect_to @group, notice: 'Group was successfully updated.'
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

  def projects
    @projects ||= current_user.authorized_projects.where(namespace_id: group.id).sorted_by_activity
  end

  def project_ids
    projects.map(&:id)
  end

  # Dont allow unauthorized access to group
  def authorize_read_group!
    unless @group and (projects.present? or can?(current_user, :read_group, @group))
      return render_404
    end
  end

  def authorize_create_group!
    unless can?(current_user, :create_group, nil)
      return render_404
    end
  end

  def authorize_admin_group!
    unless can?(current_user, :manage_group, group)
      return render_404
    end
  end

  def set_title
    @title = 'New Group'
  end

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'navless'
    else
      'group'
    end
  end

  def default_filter
    params[:scope] = 'assigned-to-me' if params[:scope].blank?
    params[:state] = 'opened' if params[:state].blank?
    params[:group_id] = @group.id
  end
end

class GroupsController < ApplicationController
  respond_to :html
  before_filter :group, except: [:new, :create]

  # Authorize
  before_filter :authorize_read_group!, except: [:new, :create]
  before_filter :authorize_admin_group!, only: [:edit, :update, :destroy]
  before_filter :authorize_create_group!, only: [:new, :create]

  # Load group projects
  before_filter :projects, except: [:new, :create]

  layout :determine_layout

  before_filter :set_title, only: [:new, :create]

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(params[:group])
    @group.path = @group.name.dup.parameterize if @group.name
    @group.owner = current_user

    if @group.save
      redirect_to @group, notice: 'Group was successfully created.'
    else
      render action: "new"
    end
  end

  def show
    @events = Event.in_projects(project_ids).limit(20).offset(params[:offset] || 0)
    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.js
      format.atom { render layout: false }
    end
  end

  # Get authored or assigned open merge requests
  def merge_requests
    @merge_requests = current_user.cared_merge_requests.of_group(@group)
    @merge_requests = FilterContext.new(@merge_requests, params).execute
    @merge_requests = @merge_requests.recent.page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @issues = current_user.assigned_issues.of_group(@group)
    @issues = FilterContext.new(@issues, params).execute
    @issues = @issues.recent.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def members
    @project = group.projects.find(params[:project_id]) if params[:project_id]
    @members = group.users_groups.order('group_access DESC')
    @users_group = UsersGroup.new
  end

  def edit
  end

  def update
    group_params = params[:group].dup
    owner_id = group_params.delete(:owner_id)

    if owner_id
      @group.owner = User.find(owner_id)
      @group.save
    end

    if @group.update_attributes(group_params)
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
    @group ||= Group.find_by_path(params[:id])
  end

  def projects
    @projects ||= current_user.authorized_projects.where(namespace_id: group.id).sorted_by_activity
  end

  def project_ids
    projects.map(&:id)
  end

  # Dont allow unauthorized access to group
  def authorize_read_group!
    unless projects.present? or can?(current_user, :manage_group, @group)
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
end

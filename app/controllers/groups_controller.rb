class GroupsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show, :issues, :members, :merge_requests]
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
    @last_push = current_user.recent_push if current_user

    respond_to do |format|
      format.html
      format.json { pager_json("events/_events", @events.count) }
      format.atom { render layout: false }
    end
  end

  def merge_requests
    @merge_requests = MergeRequestsFinder.new.execute(current_user, params)
    @merge_requests = @merge_requests.page(params[:page]).per(20)
    @merge_requests = @merge_requests.preload(:author, :target_project)
  end

  def issues
    @issues = IssuesFinder.new.execute(current_user, params)
    @issues = @issues.page(params[:page]).per(20)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def members
    @project = group.projects.find(params[:project_id]) if params[:project_id]
    @members = group.users_groups

    if params[:search].present?
      users = group.users.search(params[:search]).to_a
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
    @projects ||= ProjectsFinder.new.execute(current_user, group: group).sorted_by_activity.non_archived
  end

  def project_ids
    projects.pluck(:id)
  end

  # Dont allow unauthorized access to group
  def authorize_read_group!
    unless @group and (projects.present? or can?(current_user, :read_group, @group))
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
    elsif current_user
      'group'
    else
      'public_group'
    end
  end

  def default_filter
    if params[:scope].blank?
      if current_user
        params[:scope] = 'assigned-to-me'
      else
        params[:scope] = 'all'
      end
    end
    params[:state] = 'opened' if params[:state].blank?
    params[:group_id] = @group.id
  end
end

class GroupsController < ApplicationController
  respond_to :html
  layout 'group'

  before_filter :group
  before_filter :projects

  # Authorize
  before_filter :authorize_read_group!

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

  def search
    result = SearchContext.new(project_ids, params).execute

    @projects       = result[:projects]
    @merge_requests = result[:merge_requests]
    @issues         = result[:issues]
    @wiki_pages     = result[:wiki_pages]
  end

  def people
    @project = group.projects.find(params[:project_id]) if params[:project_id]
    @users = @project ? @project.users : group.users
    @users.sort_by!(&:name)

    if @project
      @team_member = @project.users_projects.new
    else
      @team_member = UsersProject.new
    end
  end

  def team_members
    @group.add_users_to_project_teams(params[:user_ids], params[:project_access])
    redirect_to people_group_path(@group), notice: 'Users was successfully added.'
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
end

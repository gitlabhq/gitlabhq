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
    @merge_requests = current_user.cared_merge_requests.opened
    @merge_requests = @merge_requests.of_group(@group).recent.page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @user   = current_user
    @issues = current_user.assigned_issues.opened
    @issues = @issues.of_group(@group).recent.page(params[:page]).per(20)
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
  end

  def people
    @project = group.projects.find(params[:project_id]) if params[:project_id]
    @users = @project ? @project.users : group.users
    @users.sort_by!(&:name)

    if @project
      @team_member = @project.users_projects.new
    end
  end

  protected

  def group
    @group ||= Group.find_by_path(params[:id])
  end

  def projects
    @projects ||= group.projects.authorized_for(current_user).sorted_by_activity
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

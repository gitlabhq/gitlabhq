class GroupsController < ApplicationController
  respond_to :html
  layout 'group'

  before_filter :group
  before_filter :projects

  def show
    @events = Event.where(project_id: project_ids).
      order('id DESC').
      limit(20).offset(params[:offset] || 0)

    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.js
      format.atom { render layout: false }
    end
  end

  # Get authored or assigned open merge requests
  def merge_requests
    @merge_requests = current_user.cared_merge_requests
    @merge_requests = @merge_requests.of_group(@group).order("created_at DESC").page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @user   = current_user
    @issues = current_user.assigned_issues.opened
    @issues = @issues.of_group(@group).order("created_at DESC").page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def search
    query = params[:search]

    @merge_requests = []
    @issues = []

    if query.present?
      @projects = @projects.search(query).limit(10)
      @merge_requests = MergeRequest.where(project_id: project_ids).search(query).limit(10)
      @issues = Issue.where(project_id: project_ids).search(query).limit(10)
    end
  end

  def people
    @users = group.users
  end

  protected

  def group
    @group ||= Group.find_by_code(params[:id])
  end

  def projects
    @projects ||= current_user.projects_with_events.where(group_id: @group.id)
  end

  def project_ids
    projects.map(&:id)
  end
end

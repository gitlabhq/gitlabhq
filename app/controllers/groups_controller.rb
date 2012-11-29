class GroupsController < ApplicationController
  respond_to :html
  layout 'group'

  before_filter :group
  before_filter :projects

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
    @merge_requests = current_user.cared_merge_requests
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
    @users = group.users
  end

  protected

  def group
    @group ||= Group.find_by_path(params[:id])
  end

  def projects
    @projects ||= begin
                    if can?(current_user, :manage_group, @group)
                      @group.projects
                    else
                      current_user.projects.where(namespace_id: @group.id)
                    end.sorted_by_activity.all
                  end
  end

  def project_ids
    projects.map(&:id)
  end
end

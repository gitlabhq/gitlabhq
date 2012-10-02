class DashboardController < ApplicationController
  respond_to :html

  def index
    @groups = Group.where(id: current_user.projects.pluck(:group_id))

    @projects = current_user.projects_with_events

    if params[:group].present?
      @group = Group.find_by_code(params[:group])
      @projects = @projects.where(group_id: @group.id)
    end

    @projects = @projects.page(params[:page]).per(40)

    @events = Event.recent_for_user(current_user).limit(20).offset(params[:offset] || 0)
    @last_push = current_user.recent_push

    respond_to do |format|
      format.html { render 'index', layout: determine_layout }
      format.js
      format.atom { render layout: false }
    end
  end

  # Get authored or assigned open merge requests
  def merge_requests
    @projects = current_user.projects.all
    @merge_requests = current_user.cared_merge_requests.order("created_at DESC").page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @projects = current_user.projects.all
    @user   = current_user
    @issues = current_user.assigned_issues.opened.order("created_at DESC").page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  protected

  def determine_layout
    @group ? 'group' : 'application'
  end
end

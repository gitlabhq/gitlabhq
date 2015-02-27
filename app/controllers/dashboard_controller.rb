class DashboardController < ApplicationController
  respond_to :html

  before_filter :load_projects, except: [:projects]
  before_filter :event_filter, only: :show

  def show
    # Fetch only 30 projects.
    # If user needs more - point to Dashboard#projects page
    @projects_limit = 30

    @groups = current_user.authorized_groups.order_name_asc
    @has_authorized_projects = @projects.count > 0
    @projects_count = @projects.count
    @projects = @projects.includes(:namespace).limit(@projects_limit)

    @last_push = current_user.recent_push

    @publicish_project_count = Project.publicish(current_user).count

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

  def projects
    @projects = case params[:scope]
                when 'personal' then
                  current_user.namespace.projects
                when 'joined' then
                  current_user.authorized_projects.joined(current_user)
                when 'owned' then
                  current_user.owned_projects
                else
                  current_user.authorized_projects
                end

    @projects = @projects.where(namespace_id: Group.find_by(name: params[:group])) if params[:group].present?
    @projects = @projects.where(visibility_level: params[:visibility_level]) if params[:visibility_level].present?
    @projects = @projects.includes(:namespace)
    @projects = @projects.tagged_with(params[:tag]) if params[:tag].present?
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.page(params[:page]).per(30)

    @tags = current_user.authorized_projects.tags_on(:tags)
    @groups = current_user.authorized_groups
  end

  def merge_requests
    @merge_requests = get_merge_requests_collection
    @merge_requests = @merge_requests.page(params[:page]).per(20)
    @merge_requests = @merge_requests.preload(:author, :target_project)
  end

  def issues
    @issues = get_issues_collection
    @issues = @issues.page(params[:page]).per(20)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  protected

  def load_projects
    @projects = current_user.authorized_projects.sorted_by_activity.non_archived
  end

  def load_events
    @events = Event.in_projects(current_user.authorized_projects.pluck(:id))
    @events = @event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end

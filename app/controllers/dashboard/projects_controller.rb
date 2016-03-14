class Dashboard::ProjectsController < Dashboard::ApplicationController
  include FilterProjects

  before_action :event_filter

  def index
    @projects = current_user.authorized_projects.sorted_by_activity
    @projects = filter_projects(@projects)
    @projects = @projects.includes(:namespace)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.page(params[:page]).per(PER_PAGE)

    @last_push = current_user.recent_push

    respond_to do |format|
      format.html
      format.atom do
        event_filter
        load_events
        render layout: false
      end
      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", locals: { projects: @projects })
        }
      end
    end
  end

  def starred
    @projects = current_user.starred_projects.sorted_by_activity
    @projects = filter_projects(@projects)
    @projects = @projects.includes(:namespace, :forked_from_project, :tags)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.page(params[:page]).per(PER_PAGE)

    @last_push = current_user.recent_push
    @groups = []

    respond_to do |format|
      format.html

      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", locals: { projects: @projects })
        }
      end
    end
  end

  private

  def load_events
    @events = Event.in_projects(@projects)
    @events = @event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end

class Dashboard::ProjectsController < Dashboard::ApplicationController
  include FilterProjects

  def index
    @projects = load_projects(current_user.authorized_projects)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.page(params[:page])

    respond_to do |format|
      format.html { @last_push = current_user.recent_push }
      format.atom do
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
    @projects = load_projects(current_user.viewable_starred_projects)
    @projects = @projects.includes(:forked_from_project, :tags)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.page(params[:page])

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

  def load_projects(base_scope)
    projects = base_scope.sorted_by_activity.includes(:namespace)

    filter_projects(projects)
  end

  def load_events
    @events = Event.in_projects(load_projects(current_user.authorized_projects))
    @events = event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end

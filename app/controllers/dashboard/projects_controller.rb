class Dashboard::ProjectsController < Dashboard::ApplicationController
  include ParamsBackwardCompatibility

  before_action :set_non_archived_param
  before_action :default_sorting

  def index
    @projects = load_projects(params.merge(non_public: true)).page(params[:page])

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
    @projects = load_projects(params.merge(starred: true)).
      includes(:forked_from_project, :tags).page(params[:page])

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

  def default_sorting
    params[:sort] ||= 'latest_activity_desc'
    @sort = params[:sort]
  end

  def load_projects(finder_params)
    ProjectsFinder.new(params: finder_params, current_user: current_user).
      execute.includes(:route, namespace: :route)
  end

  def load_events
    @events = Event.in_projects(load_projects(params.merge(non_public: true)))
    @events = event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end

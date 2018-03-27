class Dashboard::ProjectsController < Dashboard::ApplicationController
  include ParamsBackwardCompatibility
  include RendersMemberAccess

  before_action :set_non_archived_param
  before_action :default_sorting
  skip_cross_project_access_check :index, :starred

  def index
    @projects = load_projects(params.merge(non_public: true)).page(params[:page])

    respond_to do |format|
      format.html
      format.atom do
        load_events
        render layout: 'xml.atom'
      end
      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", locals: { projects: @projects })
        }
      end
    end
  end

  def starred
    @projects = load_projects(params.merge(starred: true))
      .includes(:forked_from_project, :tags).page(params[:page])

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
    projects = ProjectsFinder
                .new(params: finder_params, current_user: current_user)
                .execute
                .includes(:route, :creator, namespace: [:route, :owner])

    prepare_projects_for_rendering(projects)
  end

  def load_events
    projects = load_projects(params.merge(non_public: true))

    @events = EventCollection
      .new(projects, offset: params[:offset].to_i, filter: event_filter)
      .to_a

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end
end

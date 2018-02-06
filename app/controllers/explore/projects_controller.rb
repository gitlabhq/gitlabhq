class Explore::ProjectsController < Explore::ApplicationController
  include ParamsBackwardCompatibility
  include RendersMemberAccess

  before_action :set_non_archived_param

  def index
    params[:sort] ||= 'latest_activity_desc'
    @sort = params[:sort]
    @projects = load_projects

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", locals: { projects: @projects })
        }
      end
    end
  end

  def trending
    params[:trending] = true
    @sort = params[:sort]
    @projects = load_projects

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", locals: { projects: @projects })
        }
      end
    end
  end

  def starred
    @projects = load_projects.reorder('star_count DESC')

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

  def load_projects
    projects = ProjectsFinder.new(current_user: current_user, params: params)
                 .execute
                 .includes(:route, namespace: :route)
                 .page(params[:page])
                 .without_count

    prepare_projects_for_rendering(projects)
  end
end

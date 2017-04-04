class Explore::ProjectsController < Explore::ApplicationController
  include FilterProjects

  def index
    @projects = load_projects
    @tags = @projects.tags_on(:tags)
    @projects = @projects.tagged_with(params[:tag]) if params[:tag].present?
    @projects = @projects.where(visibility_level: params[:visibility_level]) if params[:visibility_level].present?
    @projects = filter_projects(@projects)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.includes(:namespace).page(params[:page])

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
    @projects = load_projects(Project.trending)
    @projects = filter_projects(@projects)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.page(params[:page])

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
    @projects = load_projects
    @projects = filter_projects(@projects)
    @projects = @projects.reorder('star_count DESC')
    @projects = @projects.page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", locals: { projects: @projects })
        }
      end
    end
  end

  protected

  def load_projects(base_scope = nil)
    base_scope ||= ProjectsFinder.new.execute(current_user)
    base_scope.includes(:route, namespace: :route)
  end
end

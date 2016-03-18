class Explore::ProjectsController < Explore::ApplicationController
  include FilterProjects

  def index
    @projects = ProjectsFinder.new.execute(current_user)
    @tags = @projects.tags_on(:tags)
    @projects = @projects.tagged_with(params[:tag]) if params[:tag].present?
    @projects = @projects.where(visibility_level: params[:visibility_level]) if params[:visibility_level].present?
    @projects = filter_projects(@projects)
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.includes(:namespace).page(params[:page]).per(PER_PAGE)

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
    @projects = TrendingProjectsFinder.new.execute(current_user)
    @projects = filter_projects(@projects)
    @projects = @projects.page(params[:page]).per(PER_PAGE)

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
    @projects = ProjectsFinder.new.execute(current_user)
    @projects = filter_projects(@projects)
    @projects = @projects.reorder('star_count DESC')
    @projects = @projects.page(params[:page]).per(PER_PAGE)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("dashboard/projects/_projects", locals: { projects: @projects })
        }
      end
    end
  end
end

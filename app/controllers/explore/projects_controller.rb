# frozen_string_literal: true

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
          html: view_to_html_string("explore/projects/_projects", projects: @projects)
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
          html: view_to_html_string("explore/projects/_projects", projects: @projects)
        }
      end
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def starred
    @projects = load_projects.reorder('star_count DESC')

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("explore/projects/_projects", projects: @projects)
        }
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def load_projects
    @total_user_projects_count = ProjectsFinder.new(params: { non_public: true }, current_user: current_user).execute
    @total_starred_projects_count = ProjectsFinder.new(params: { starred: true }, current_user: current_user).execute

    projects = ProjectsFinder.new(current_user: current_user, params: params)
                 .execute
                 .includes(:route, :creator, :group, namespace: [:route, :owner])
                 .page(params[:page])
                 .without_count

    prepare_projects_for_rendering(projects)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

# frozen_string_literal: true

class Projects::ForksController < Projects::ApplicationController
  include ContinueParams
  include RendersMemberAccess

  # Authorize
  before_action :whitelist_query_limiting, only: [:create]
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authenticate_user!, only: [:new, :create]
  before_action :authorize_fork_project!, only: [:new, :create]

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @total_forks_count    = project.forks.size
    @public_forks_count   = project.forks.public_only.size
    @private_forks_count  = @total_forks_count - project.forks.public_and_internal_only.size
    @internal_forks_count = @total_forks_count - @public_forks_count - @private_forks_count

    @forks = ForkProjectsFinder.new(project, params: params.merge(search: params[:filter_projects]), current_user: current_user).execute
    @forks = @forks.includes(:route, :creator, :group, namespace: [:route, :owner])
                   .page(params[:page])

    prepare_projects_for_rendering(@forks)

    respond_to do |format|
      format.html

      format.json do
        render json: {
          html: view_to_html_string("projects/forks/_projects", projects: @forks)
        }
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def new
    @namespaces = current_user.manageable_namespaces
    @namespaces.delete(@project.namespace)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def create
    namespace = Namespace.find(params[:namespace_key])

    @forked_project = namespace.projects.find_by(path: project.path)
    @forked_project = nil unless @forked_project && @forked_project.forked_from_project == project

    @forked_project ||= ::Projects::ForkService.new(project, current_user, namespace: namespace).execute

    if !@forked_project.saved? || !@forked_project.forked?
      render :error
    elsif @forked_project.import_in_progress?
      redirect_to project_import_path(@forked_project, continue: continue_params)
    elsif continue_params[:to]
      redirect_to continue_params[:to], notice: continue_params[:notice]
    else
      redirect_to project_path(@forked_project), notice: "The project '#{@forked_project.name}' was successfully forked."
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42335')
  end
end

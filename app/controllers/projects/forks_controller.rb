# frozen_string_literal: true

class Projects::ForksController < Projects::ApplicationController
  include ContinueParams
  include RendersMemberAccess
  include RendersProjectsList
  include Gitlab::Utils::StrongMemoize

  # Authorize
  before_action :disable_query_limiting, only: [:create]
  before_action :require_non_empty_project
  before_action :authorize_read_code!
  before_action :authenticate_user!, only: [:new, :create]
  before_action :authorize_fork_project!, except: [:index]
  before_action :authorize_fork_namespace!, only: [:create]

  feature_category :source_code_management
  urgency :low, [:index]

  def index
    @sort = forks_params[:sort]

    @total_forks_count    = project.forks.size
    @public_forks_count   = project.forks.public_only.size
    @private_forks_count  = @total_forks_count - project.forks.public_and_internal_only.size
    @internal_forks_count = @total_forks_count - @public_forks_count - @private_forks_count

    @forks = load_forks.page(forks_params[:page])

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

  def new
    respond_to do |format|
      format.html do
        @own_namespace = current_user.namespace if can_fork_to?(current_user.namespace)
        @project = project
      end

      format.json do
        namespaces = load_namespaces_with_associations - [project.namespace]

        namespaces = [current_user.namespace] + namespaces if can_fork_to?(current_user.namespace)

        render json: {
          namespaces: ForkNamespaceSerializer.new.represent(
            namespaces,
            project: project,
            current_user: current_user,
            memberships: memberships_hash,
            forked_projects: forked_projects_by_namespace(namespaces)
          )
        }
      end
    end
  end

  def create
    @forked_project = fork_namespace.projects.find_by(path: project.path) # rubocop: disable CodeReuse/ActiveRecord
    @forked_project = nil unless @forked_project && @forked_project.forked_from_project == project

    unless @forked_project
      @fork_response = fork_service.execute

      @forked_project ||= @fork_response[:project] if @fork_response.success?
    end

    if defined?(@fork_response) && @fork_response.error?
      render :error
    elsif @forked_project.import_in_progress?
      redirect_to project_import_path(@forked_project, continue: continue_params)
    elsif continue_params[:to]
      redirect_to continue_params[:to], notice: continue_params[:notice]
    else
      redirect_to project_path(@forked_project),
        notice: "The project '#{@forked_project.name}' was successfully forked."
    end
  end

  private

  def can_fork_to?(namespace)
    ForkTargetsFinder.new(@project, current_user).execute.id_in(current_user.namespace).any?
  end

  def load_forks
    forks = ForkProjectsFinder.new(
      project,
      params: forks_params.merge(search: forks_params[:filter_projects]),
      current_user: current_user
    ).execute

    # rubocop: disable CodeReuse/ActiveRecord
    forks.includes(:route, :creator, :group, :topics, namespace: [:route, :owner])
    # rubocop: enable CodeReuse/ActiveRecord
  end

  def fork_service
    strong_memoize(:fork_service) do
      ::Projects::ForkService.new(project, current_user, fork_params)
    end
  end

  def fork_namespace
    strong_memoize(:fork_namespace) do
      Namespace.find(params[:namespace_key]) if params[:namespace_key].present?
    end
  end

  def forks_params
    params.permit(:filter_projects, :sort, :page)
  end

  def fork_params
    params.permit(:path, :name, :description, :visibility).tap do |param|
      param[:namespace] = fork_namespace
    end
  end

  def authorize_fork_namespace!
    access_denied! unless fork_namespace && fork_service.valid_fork_target?
  end

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20783')
  end

  def load_namespaces_with_associations
    @load_namespaces_with_associations ||= fork_service
      .valid_fork_targets(only_groups: true)
      .with_deletion_schedule_only
      .with_route
      .with_namespace_details
  end

  def memberships_hash
    # rubocop: disable CodeReuse/ActiveRecord
    current_user.members.where(source: load_namespaces_with_associations).index_by(&:source_id)
    # rubocop: enable CodeReuse/ActiveRecord
  end

  def forked_projects_by_namespace(namespaces)
    # rubocop: disable CodeReuse/ActiveRecord
    project.forks.where(namespace: namespaces).includes(:namespace).index_by(&:namespace_id)
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

Projects::ForksController.prepend_mod_with('Projects::ForksController')

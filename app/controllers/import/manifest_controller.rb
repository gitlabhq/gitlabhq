class Import::ManifestController < Import::BaseController
  before_action :whitelist_query_limiting, only: [:create]
  before_action :verify_import_enabled
  before_action :ensure_import_vars, only: [:create, :status]

  def new
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def status
    @already_added_projects = find_already_added_projects
    already_added_import_urls = @already_added_projects.pluck(:import_url)

    @pending_repositories = repositories.to_a.reject do |repository|
      already_added_import_urls.include?(repository[:url])
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def upload
    group = Group.find(params[:group_id])

    unless can?(current_user, :create_projects, group)
      @errors = ["You don't have enough permissions to create projects in the selected group"]

      render :new && return
    end

    manifest = Gitlab::ManifestImport::Manifest.new(params[:manifest].tempfile)

    if manifest.valid?
      session[:manifest_import_repositories] = manifest.projects
      session[:manifest_import_group_id] = group.id

      redirect_to status_import_manifest_path
    else
      @errors = manifest.errors

      render :new
    end
  end

  def jobs
    render json: find_jobs
  end

  def create
    repository = repositories.find do |project|
      project[:id] == params[:repo_id].to_i
    end

    project = Gitlab::ManifestImport::ProjectCreator.new(repository, group, current_user).execute

    if project.persisted?
      render json: ProjectSerializer.new.represent(project)
    else
      render json: { errors: project_save_error(project) }, status: :unprocessable_entity
    end
  end

  private

  def ensure_import_vars
    unless group && repositories.present?
      redirect_to(new_import_manifest_path)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def group
    @group ||= Group.find_by(id: session[:manifest_import_group_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def repositories
    @repositories ||= session[:manifest_import_repositories]
  end

  def find_jobs
    find_already_added_projects.to_json(only: [:id], methods: [:import_status])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def find_already_added_projects
    group.all_projects
      .where(import_type: 'manifest')
      .where(creator_id: current_user)
      .includes(:import_state)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def verify_import_enabled
    render_404 unless manifest_import_enabled?
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/48939')
  end
end

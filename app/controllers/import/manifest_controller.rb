class Import::ManifestController < Import::BaseController
  before_action :ensure_import_vars, only: [:create, :status]

  def new
  end

  def status
    @already_added_projects = find_already_added_projects
    already_added_import_urls = @already_added_projects.pluck(:import_url)

    @pending_repositories = repositories.to_a.reject do |repository|
      already_added_import_urls.include?(repository[:url])
    end
  end

  def upload
    group = Group.find(params[:group_id])

    unless can?(current_user, :create_projects, group)
      @errors = ["You don't have enough permissions to create projects in the selected group"]

      render :new && return
    end

    manifest = Gitlab::ManifestImport::Manifest.new(params[:manifest].tempfile)

    if manifest.valid?
      session[:repositories] = manifest.projects
      session[:group_id] = group.id

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

    project = Gitlab::ManifestImport::Importer.new(repository, group, current_user).execute

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

  def group
    @group ||= Group.find_by(id: session[:group_id])
  end

  def repositories
    @repositories ||= session[:repositories]
  end

  def find_jobs
    find_already_added_projects.to_json(only: [:id], methods: [:import_status])
  end

  def find_already_added_projects
    group.all_projects
      .where(import_type: 'manifest')
      .where(creator_id: current_user)
      .includes(:import_state)
  end
end

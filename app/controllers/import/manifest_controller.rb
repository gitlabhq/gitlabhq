class Import::ManifestController < Import::BaseController
  before_action :ensure_session, only: [:create, :status, :jobs]
  before_action :group, only: [:status, :create]

  def new
  end

  def status
    @repos = session[:projects]

    @already_added_projects = find_already_added_projects('manifest').where(namespace_id: group)
    already_added_projects_names = @already_added_projects.pluck(:import_url)

    @repos = @repos.to_a.reject { |repo| already_added_projects_names.include? repo[:url] }
  end

  def upload
    group = Group.find(params[:group_id])

    unless can?(current_user, :create_projects, group)
      @errors = ["You don't have enough permissions to create projects in the selected group"]

      render :new && return
    end

    manifest = Gitlab::ManifestImport::Manifest.new(params[:manifest].tempfile)

    if manifest.valid?
      session[:projects] = manifest.projects
      session[:group_id] = group.id

      flash[:notice] = "Import successfully started."

      redirect_to status_import_manifest_path
    else
      @errors = manifest.errors

      render :new
    end
  end

  def jobs
    render json: find_jobs('manifest')
  end

  def create
    repository = session[:projects].find do |project|
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

  def ensure_session
    if session[:projects].blank? || session[:group_id].blank?
      redirect_to(new_import_manifest_path)
    end
  end

  def group
    @group ||= Group.find(session[:group_id])
  end
end

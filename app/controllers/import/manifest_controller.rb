# frozen_string_literal: true

class Import::ManifestController < Import::BaseController
  extend ::Gitlab::Utils::Override

  MAX_MANIFEST_SIZE_IN_MB = 1

  before_action :disable_query_limiting, only: [:create]
  before_action :verify_import_enabled
  before_action :ensure_import_vars, only: [:create, :status]
  before_action :check_file_size, only: [:upload]

  def new; end

  # We need to re-expose controller's internal method 'status' as action.
  # rubocop:disable Lint/UselessMethodDefinition
  def status
    super
  end
  # rubocop:enable Lint/UselessMethodDefinition

  def upload
    group = Group.find(params[:group_id])

    unless can?(current_user, :import_projects, group)
      @errors = ["You don't have enough permissions to import projects in the selected group"]

      render(:new) && return
    end

    manifest = Gitlab::ManifestImport::Manifest.new(params[:manifest].tempfile)

    if manifest.valid?
      manifest_import_metadata.save(manifest.projects, group.id)

      redirect_to status_import_manifest_path
    else
      @errors = manifest.errors

      render :new
    end
  end

  def create
    repository = importable_repos.find do |project|
      project[:id] == params[:repo_id].to_i
    end

    project = Gitlab::ManifestImport::ProjectCreator.new(repository, group, current_user).execute

    if project.persisted?
      render json: ProjectSerializer.new.represent(project, serializer: :import)
    else
      render json: { errors: project_save_error(project) }, status: :unprocessable_entity
    end
  end

  protected

  override :importable_repos
  def importable_repos
    @importable_repos ||= manifest_import_metadata.repositories
  end

  override :incompatible_repos
  def incompatible_repos
    []
  end

  override :provider_name
  def provider_name
    :manifest
  end

  override :provider_url
  def provider_url
    nil
  end

  override :extra_representation_opts
  def extra_representation_opts
    { group_full_path: group.full_path }
  end

  private

  def ensure_import_vars
    redirect_to(new_import_manifest_path) unless group && importable_repos.present?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def group
    @group ||= Group.find_by(id: manifest_import_metadata.group_id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def manifest_import_metadata
    @manifest_import_status ||= Gitlab::ManifestImport::Metadata.new(current_user, fallback: session)
  end

  def find_jobs
    find_already_added_projects.to_json(only: [:id], methods: [:import_status])
  end

  def verify_import_enabled
    render_404 unless manifest_import_enabled?
  end

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/23147')
  end

  def check_file_size
    return if params[:manifest].tempfile.size <= MAX_MANIFEST_SIZE_IN_MB.megabytes

    @errors = [
      format(s_("ManifestImport|Import manifest files cannot exceed %{size} MB"), size: MAX_MANIFEST_SIZE_IN_MB)
    ]

    render(:new)
  end
end

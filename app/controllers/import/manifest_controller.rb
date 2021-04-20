# frozen_string_literal: true

class Import::ManifestController < Import::BaseController
  extend ::Gitlab::Utils::Override

  before_action :disable_query_limiting, only: [:create]
  before_action :verify_import_enabled
  before_action :ensure_import_vars, only: [:create, :status]

  def new
  end

  def status
    super
  end

  def upload
    group = Group.find(params[:group_id])

    unless can?(current_user, :create_projects, group)
      @errors = ["You don't have enough permissions to create projects in the selected group"]

      render :new && return
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

  def realtime_changes
    super
  end

  def create
    repository = repositories.find do |project|
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

  # rubocop: disable CodeReuse/ActiveRecord
  override :importable_repos
  def importable_repos
    already_added_projects_names = already_added_projects.pluck(:import_url)

    repositories.reject { |repo| already_added_projects_names.include?(repo[:url]) }
  end
  # rubocop: enable CodeReuse/ActiveRecord

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
    unless group && repositories.present?
      redirect_to(new_import_manifest_path)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def group
    @group ||= Group.find_by(id: manifest_import_metadata.group_id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def manifest_import_metadata
    @manifest_import_status ||= Gitlab::ManifestImport::Metadata.new(current_user, fallback: session)
  end

  def repositories
    @repositories ||= manifest_import_metadata.repositories
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
end

class Projects::ArtifactsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_build!
  before_action :authorize_update_build!, only: [:keep]
  before_action :validate_artifacts!

  def download
    if artifacts_file.file_storage?
      send_file artifacts_file.path, disposition: 'attachment'
    else
      redirect_to artifacts_file.url
    end
  end

  def browse
    directory = params[:path] ? "#{params[:path]}/" : ''
    @entry = build.artifacts_metadata_entry(directory)

    render_404 unless @entry.exists?
  end

  def file
    entry = build.artifacts_metadata_entry(params[:path])

    if entry.exists?
      send_artifacts_entry(build, entry)
    else
      render_404
    end
  end

  def keep
    build.keep_artifacts!
    redirect_to namespace_project_build_path(project.namespace, project, build)
  end

  def latest_succeeded
    target_url = artifacts_action_url(params[:path], project, build)

    if target_url
      redirect_to(target_url)
    else
      render_404
    end
  end

  private

  def validate_artifacts!
    render_404 unless build && build.artifacts?
  end

  def build
    @build ||= build_from_id || build_from_ref
  end

  def build_from_id
    project.builds.find_by(id: params[:build_id]) if params[:build_id]
  end

  def build_from_ref
    if params[:ref_name]
      builds = project.latest_successful_builds_for(params[:ref_name])

      builds.find_by(name: params[:job])
    end
  end

  def artifacts_file
    @artifacts_file ||= build.artifacts_file
  end
end

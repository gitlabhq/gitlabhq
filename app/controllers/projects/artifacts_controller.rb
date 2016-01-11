class Projects::ArtifactsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_download_build_artifacts!

  def download
    unless artifacts_file.file_storage?
      return redirect_to artifacts_file.url
    end

    unless artifacts_file.exists?
      return not_found!
    end

    send_file artifacts_file.path, disposition: 'attachment'
  end

  def browse
    return render_404 unless build.artifacts?

    directory = params[:path] ? "#{params[:path]}/" : ''
    @path = build.artifacts_metadata_path(directory)

    return render_404 unless @path.exists?
  end

  def file
    file = build.artifacts_metadata_path(params[:path])

    if file.exists?
      render json: { repository: build.artifacts_file.path,
                     path: Base64.encode64(file.path) }
    else
      render json: {}, status: 404
    end
  end

  private

  def build
    @build ||= project.builds.unscoped.find_by!(id: params[:build_id])
  end

  def artifacts_file
    @artifacts_file ||= build.artifacts_file
  end

  def authorize_download_build_artifacts!
    unless can?(current_user, :download_build_artifacts, @project)
      if current_user.nil?
        return authenticate_user!
      else
        return render_404
      end
    end
  end
end

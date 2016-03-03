class Projects::ArtifactsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_build!

  def download
    unless artifacts_file.file_storage?
      return redirect_to artifacts_file.url
    end

    unless artifacts_file.exists?
      return render_404
    end

    send_file artifacts_file.path, disposition: 'attachment'
  end

  def browse
    return render_404 unless build.artifacts?

    directory = params[:path] ? "#{params[:path]}/" : ''
    @entry = build.artifacts_metadata_entry(directory)

    return render_404 unless @entry.exists?
  end

  def file
    entry = build.artifacts_metadata_entry(params[:path])

    if entry.exists?
      render json: { archive: build.artifacts_file.path,
                     entry: Base64.encode64(entry.path) }
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
end

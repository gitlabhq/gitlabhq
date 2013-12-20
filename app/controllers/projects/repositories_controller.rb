class Projects::RepositoriesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def stats
    @stats = Gitlab::Git::Stats.new(@repository.raw, @repository.root_ref)
    @graph = @stats.graph
  end

  def archive
    unless can?(current_user, :download_code, @project)
      render_404 and return
    end

    storage_path = Rails.root.join("tmp", "repositories")

    file_path = @repository.archive_repo(params[:ref], storage_path, params[:format].downcase)

    if file_path
      # Send file to user
      send_file file_path
    else
      render_404
    end
  end
end

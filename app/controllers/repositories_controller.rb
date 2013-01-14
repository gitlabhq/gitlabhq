class RepositoriesController < ProjectResourceController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    @activities = @repository.commits_with_refs(20)
  end

  def branches
    @branches = @repository.branches
  end

  def tags
    @tags = @repository.tags
  end

  def stats
    @stats = Gitlab::GitStats.new(@repository.raw, @repository.root_ref)
    @graph = @stats.graph
  end

  def archive
    unless can?(current_user, :download_code, @project)
      render_404 and return
    end


    file_path = @repository.archive_repo(params[:ref])

    if file_path
      # Send file to user
      send_file file_path
    else
      render_404
    end
  end
end

class RepositoriesController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project
  before_filter :render_full_content

  layout "project"

  def show
    @activities = @project.commits_with_refs(20)
  end

  def branches
    @branches = @project.repo.heads.sort_by(&:name)
  end

  def tags
    @tags = @project.repo.tags.sort_by(&:name).reverse
  end

  def archive
    unless can?(current_user, :download_code, @project)
      render_404 and return 
    end


    file_path = @project.archive_repo(params[:ref])

    if file_path
      # Send file to user
      send_file file_path
    else
      render_404
    end
  end
end

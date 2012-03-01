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

    ref = params[:ref] || @project.root_ref
    commit = @project.commit(ref)
    render_404 and return unless commit

    # Build file path
    file_name = @project.code + "-" + commit.id.to_s + ".tar.gz"
    storage_path = File.join(Rails.root, "tmp", "repositories", @project.code)
    file_path = File.join(storage_path, file_name)

    # Create file if not exists
    unless File.exists?(file_path)
      FileUtils.mkdir_p storage_path
      file = @project.repo.archive_to_file(ref, nil,  file_path)
    end

    # Send file to user
    send_file file_path
  end
end

# Controller for viewing a repository's file structure
class TreeController < ProjectResourceController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :assign_ref_vars

  def show
    @hex_path = Digest::SHA1.hexdigest(@path)

    @history_path = project_tree_path(@project, @id)
    @logs_path    = logs_file_project_ref_path(@project, @ref, @path)

    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end
end

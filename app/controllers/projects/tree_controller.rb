# Controller for viewing a repository's file structure
class Projects::TreeController < Projects::BaseTreeController
  def show
    @repo_stats = @repository.language_stats
    return not_found! if tree.entries.empty?

    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end
end

# Controller for viewing a repository's file structure
class Projects::TreeFilterController < Projects::ApplicationController
  include ExtractsPath
  include ActionView::Helpers::SanitizeHelper

  before_action :assign_ref_vars

  def show
    return render_404 unless @repository.commit(@ref)

    r = Grit::Repo.new(@repo.path_to_repo, { is_bare: true })
    @tree_filter_list = r.lstree(@ref, recursive: true)

    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end
end

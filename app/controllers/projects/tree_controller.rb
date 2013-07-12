# Controller for viewing a repository's file structure
class Projects::TreeController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end
end

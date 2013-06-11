class GraphsController < ProjectResourceController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    respond_to do |format|
      format.html
      format.js do
        @repo = @project.repository
        @stats = Gitlab::Git::GitStats.new(@repo.raw, @repo.root_ref)
        @log = @stats.parsed_log.to_json
      end
    end
  end
end

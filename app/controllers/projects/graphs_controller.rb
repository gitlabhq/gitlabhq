class Projects::GraphsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    respond_to do |format|
      format.html
      format.js do
        fetch_graph
      end
    end
  end

  private

  def fetch_graph
    @log = @project.repository.graph_log.to_json
    @success = true
  rescue => ex
    @log = []
    @success = false
  end
end

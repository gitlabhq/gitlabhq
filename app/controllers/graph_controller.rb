class GraphController < ProjectResourceController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    respond_to do |format|
      format.html
      format.json do
        graph = Gitlab::Graph::JsonBuilder.new(project, @ref)
        render :json => graph.to_json
      end
    end
  end
end

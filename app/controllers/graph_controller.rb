class GraphController < ProjectResourceController
  include ExtractsPath
  include ApplicationHelper

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    if params.has_key?(:q)
      if params[:q].blank?
        redirect_to project_graph_path(@project, params[:id])
        return
      end

      @q = params[:q]
      @commit = @project.repository.commit(@q) || @commit
    end

    respond_to do |format|
      format.html

      format.json do
        @graph = Network::Graph.new(project, @ref, @commit)
      end
    end
  end
end

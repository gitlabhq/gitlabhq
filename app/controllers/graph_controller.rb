class GraphController < ProjectResourceController
  include ExtractsPath
  include ApplicationHelper

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    if params.has_key?(:q) && params[:q].blank?
      redirect_to project_graph_path(@project, params[:id])
      return
    end

    if params.has_key?(:q)
      @q = params[:q]
      @commit = @project.repository.commit(@q) || @commit
    end

    respond_to do |format|
      format.html
      format.json do
        graph = Graph::JsonBuilder.new(project, @ref, @commit)
        graph.commits.each do |c|
          c.icon = gravatar_icon(c.author.email)
        end
        render :json => graph.to_json
      end
    end
  end
end

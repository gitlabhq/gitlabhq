class NetworkController < ProjectResourceController
  include ExtractsPath
  include ApplicationHelper

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    if @options[:q]
      @commit = @project.repository.commit(@options[:q]) || @commit
    end

    respond_to do |format|
      format.html

      format.json do
        @graph = Network::Graph.new(project, @ref, @commit, @options[:filter_ref])
      end
    end
  end
end

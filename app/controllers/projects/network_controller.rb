class Projects::NetworkController < Projects::ApplicationController
  include ExtractsPath
  include ApplicationHelper

  before_filter :require_non_empty_project
  before_filter :assign_ref_vars
  before_filter :authorize_download_code!

  def show
    respond_to do |format|
      format.html

      format.json do
        @graph = Network::Graph.new(project, @ref, @commit, @options[:filter_ref])
      end
    end
  end
end

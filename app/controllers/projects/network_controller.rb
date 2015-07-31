class Projects::NetworkController < Projects::ApplicationController
  include ExtractsPath
  include ApplicationHelper

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show

    @url = namespace_project_network_path(@project.namespace, @project, @ref, @options.merge(format: :json))
    @commit_url = namespace_project_commit_path(@project.namespace, @project, 'ae45ca32').gsub("ae45ca32", "%s")

    respond_to do |format|
      format.html

      format.json do
        @graph = Network::Graph.new(project, @ref, @commit, @options[:filter_ref])
      end
    end
  end
end

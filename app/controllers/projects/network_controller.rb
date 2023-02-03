# frozen_string_literal: true

class Projects::NetworkController < Projects::ApplicationController
  include ExtractsPath
  include ApplicationHelper

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_read_code!
  before_action :assign_options
  before_action :assign_commit

  feature_category :source_code_management
  urgency :low, [:show]

  def show
    @url = project_network_path(@project, @ref, @options.merge(format: :json, ref_type: ref_type))

    @ref_type = ref_type
    @commit_url = project_commit_path(@project, 'ae45ca32').gsub("ae45ca32", "%s")

    respond_to do |format|
      format.html do
        if @options[:extended_sha1] && !@commit
          flash.now[:alert] = "Git revision '#{@options[:extended_sha1]}' does not exist."
        end
      end

      format.json do
        @graph = Network::Graph.new(project, @ref, @commit, @options[:filter_ref])
      end
    end

    render
  end

  def assign_options
    @options = params.permit(:filter_ref, :extended_sha1)
  end

  def assign_commit
    return if @options[:extended_sha1].blank?

    @commit = @repo.commit(@options[:extended_sha1])
  end
end

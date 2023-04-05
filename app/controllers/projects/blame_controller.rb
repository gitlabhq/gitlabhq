# frozen_string_literal: true

# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath
  include RedirectsForMissingPathOnTree

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_read_code!

  feature_category :source_code_management
  urgency :low, [:show]

  def show
    @blob = @repository.blob_at(@commit.id, @path)

    unless @blob
      return redirect_to_tree_root_for_missing_path(@project, @ref, @path)
    end

    load_environment

    blame_service = Projects::BlameService.new(@blob, @commit, blame_params)

    @blame = Gitlab::View::Presenter::Factory.new(blame_service.blame, project: @project, path: @path, page: blame_service.page).fabricate!

    @streaming_possible = blame_service.streaming_possible

    @streaming_enabled = blame_service.streaming_enabled
    @blame_pagination = blame_service.pagination unless @streaming_enabled

    @blame_per_page = blame_service.per_page

    render locals: { total_extra_pages: blame_service.total_extra_pages }
  end

  def page
    @blob = @repository.blob_at(@commit.id, @path)

    load_environment

    blame_service = Projects::BlameService.new(@blob, @commit, blame_params)

    @blame = Gitlab::View::Presenter::Factory.new(blame_service.blame, project: @project, path: @path, page: blame_service.page).fabricate!

    render partial: 'page'
  end

  private

  def load_environment
    environment_params = @repository.branch_exists?(@ref) ? { ref: @ref } : { commit: @commit }
    environment_params[:find_latest] = true
    @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(@project, current_user, environment_params).execute.last
  end

  def blame_params
    params.permit(:page, :no_pagination, :streaming)
  end
end

Projects::BlameController.prepend_mod

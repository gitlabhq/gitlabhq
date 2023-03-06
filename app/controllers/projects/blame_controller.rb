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

    environment_params = @repository.branch_exists?(@ref) ? { ref: @ref } : { commit: @commit }
    environment_params[:find_latest] = true
    @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(@project, current_user, environment_params).execute.last

    permitted_params = params.permit(:page, :no_pagination, :streaming)
    blame_service = Projects::BlameService.new(@blob, @commit, permitted_params)

    @blame = Gitlab::View::Presenter::Factory.new(blame_service.blame, project: @project, path: @path, page: blame_service.page).fabricate!

    @entire_blame_path = full_blame_path(no_pagination: true)
    @blame_pages_url = blame_pages_url(permitted_params)
    if blame_service.streaming_possible
      @entire_blame_path = full_blame_path(streaming: true)
    end

    @streaming_enabled = blame_service.streaming_enabled
    @blame_pagination = blame_service.pagination unless @streaming_enabled

    @blame_per_page = blame_service.per_page

    render locals: { total_extra_pages: blame_service.total_extra_pages }
  end

  def page
    @blob = @repository.blob_at(@commit.id, @path)

    environment_params = @repository.branch_exists?(@ref) ? { ref: @ref } : { commit: @commit }
    environment_params[:find_latest] = true
    @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(@project, current_user, environment_params).execute.last

    blame_service = Projects::BlameService.new(@blob, @commit, params.permit(:page, :streaming))

    @blame = Gitlab::View::Presenter::Factory.new(blame_service.blame, project: @project, path: @path, page: blame_service.page).fabricate!

    render partial: 'page'
  end

  private

  def full_blame_path(params)
    namespace_project_blame_path(namespace_id: @project.namespace, project_id: @project, id: @id, **params)
  end

  def blame_pages_url(params)
    namespace_project_blame_page_url(namespace_id: @project.namespace, project_id: @project, id: @id, **params)
  end
end

Projects::BlameController.prepend_mod

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

    blame_service = Projects::BlameService.new(@blob, @commit, params.permit(:page, :no_pagination))

    @blame = Gitlab::View::Presenter::Factory.new(blame_service.blame, project: @project, path: @path, page: blame_service.page).fabricate!

    @blame_pagination = blame_service.pagination

    @blame_per_page = blame_service.per_page
  end
end

Projects::BlameController.prepend_mod

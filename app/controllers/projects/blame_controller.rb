# frozen_string_literal: true

# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath
  include RedirectsForMissingPathOnTree

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_read_code!
  before_action :load_blob
  before_action :require_non_binary_blob

  feature_category :source_code_management
  urgency :low, [:show]

  def show
    @ref_type = ref_type
    load_environment
    load_blame
  end

  def streaming
    show
    render action: 'show'
  end

  def page
    load_environment
    load_blame

    render partial: 'page'
  end

  private

  def load_blob
    @blob = @repository.blob_at(@commit.id, @path)

    return if @blob

    redirect_to_tree_root_for_missing_path(@project, @ref, @path)
  end

  def require_non_binary_blob
    return unless @blob.binary?

    redirect_to project_blob_path(@project, File.join(@ref, @path)),
      notice: _('Blame for binary files is not supported.')
  end

  def load_environment
    environment_params = @repository.branch_exists?(@ref) ? { ref: @ref } : { commit: @commit }
    environment_params[:find_latest] = true
    @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(
      @project,
      current_user,
      environment_params
    ).execute.last
  end

  def load_blame
    @blame_mode = Gitlab::Git::BlameMode.new(@commit.project, blame_params)
    @blame_pagination = Gitlab::Git::BlamePagination.new(@blob, @blame_mode, blame_params)

    blame = Gitlab::Blame.new(@blob, @commit, range: @blame_pagination.blame_range)
    @blame = Gitlab::View::Presenter::Factory.new(
      blame,
      project: @project,
      path: @path,
      page: @blame_pagination.page
    ).fabricate!
  end

  def blame_params
    params.permit(:page, :no_pagination, :streaming)
  end
end

Projects::BlameController.prepend_mod

# Controller for viewing a repository's file structure
class Projects::TreeController < Projects::ApplicationController
  include ExtractsPath
  include CreatesCommit
  include ActionView::Helpers::SanitizeHelper

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :assign_ref_vars
  before_action :assign_dir_vars, only: [:create_dir]
  before_action :authorize_download_code!
  before_action :authorize_edit_tree!, only: [:create_dir]

  def show
    return render_404 unless @repository.commit(@ref)

    if tree.entries.empty?
      if @repository.blob_at(@commit.id, @path)
        return redirect_to(
          project_blob_path(@project,
                                      File.join(@ref, @path))
        )
      elsif @path.present?
        return render_404
      end
    end

    respond_to do |format|
      format.html do
        lfs_blob_ids
        @last_commit = @repository.last_commit_for_path(@commit.id, @tree.path) || @commit
      end

      format.js do
        # Disable cache so browser history works
        no_cache_headers
      end

      format.json do
        page_title @path.presence || _("Files"), @ref, @project.full_name

        # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/38261
        Gitlab::GitalyClient.allow_n_plus_1_calls do
          render json: TreeSerializer.new(project: @project, repository: @repository, ref: @ref).represent(@tree)
        end
      end
    end
  end

  def create_dir
    return render_404 unless @commit_params.values.all?

    create_commit(Files::CreateDirService,  success_notice: "The directory has been successfully created.",
                                            success_path: project_tree_path(@project, File.join(@branch_name, @dir_name)),
                                            failure_path: project_tree_path(@project, @ref))
  end

  private

  def assign_dir_vars
    @branch_name = params[:branch_name]

    @dir_name = File.join(@path, params[:dir_name])
    @commit_params = {
      file_path: @dir_name,
      commit_message: params[:commit_message]
    }
  end
end

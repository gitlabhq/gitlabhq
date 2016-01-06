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
        redirect_to(
          namespace_project_blob_path(@project.namespace, @project,
                                      File.join(@ref, @path))
        ) and return
      elsif @path.present?
        return render_404
      end
    end

    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end

  def create_dir
    return render_404 unless @commit_params.values.all?

    create_commit(Files::CreateDirService,  success_notice: "The directory has been successfully created.",
                                            success_path: namespace_project_tree_path(@project.namespace, @project, File.join(@target_branch, @dir_name)),
                                            failure_path: namespace_project_tree_path(@project.namespace, @project, @ref))
  end

  private

  def assign_dir_vars
    @target_branch = params[:target_branch]

    @dir_name = File.join(@path, params[:dir_name])
    @commit_params = {
      file_path: @dir_name,
      commit_message: params[:commit_message],
    }
  end
end

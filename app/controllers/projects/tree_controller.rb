# frozen_string_literal: true

# Controller for viewing a repository's file structure
class Projects::TreeController < Projects::ApplicationController
  include ExtractsPath
  include CreatesCommit
  include ActionView::Helpers::SanitizeHelper
  include RedirectsForMissingPathOnTree

  around_action :allow_gitaly_ref_name_caching, only: [:show]

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :assign_ref_vars
  before_action :assign_dir_vars, only: [:create_dir]
  before_action :authorize_download_code!
  before_action :authorize_edit_tree!, only: [:create_dir]

  feature_category :source_code_management

  def show
    return render_404 unless @commit

    if tree.entries.empty?
      if @repository.blob_at(@commit.id, @path)
        redirect_to project_blob_path(@project, File.join(@ref, @path))
      elsif @path.present?
        redirect_to_tree_root_for_missing_path(@project, @ref, @path)
      end
    end
  end

  def create_dir
    return render_404 unless @commit_params.values.all?

    create_commit(Files::CreateDirService,  success_notice: _("The directory has been successfully created."),
                                            success_path: project_tree_path(@project, File.join(@branch_name, @dir_name)),
                                            failure_path: project_tree_path(@project, @ref))
  end

  private

  def redirect_renamed_default_branch?
    action_name == 'show'
  end

  def assign_dir_vars
    @branch_name = params[:branch_name]

    @dir_name = File.join(@path, params[:dir_name])
    @commit_params = {
      file_path: @dir_name,
      commit_message: params[:commit_message]
    }
  end
end

# frozen_string_literal: true

# Controller for viewing a repository's file structure
class Projects::TreeController < Projects::ApplicationController
  include ExtractsPath
  include CreatesCommit
  include ActionView::Helpers::SanitizeHelper
  include RedirectsForMissingPathOnTree
  include SourcegraphDecorator

  around_action :allow_gitaly_ref_name_caching, only: [:show]

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :assign_ref_vars
  before_action :set_is_ambiguous_ref, only: [:show]
  before_action :find_requested_ref, only: [:show]
  before_action :assign_dir_vars, only: [:create_dir]
  before_action :authorize_read_code!
  before_action :authorize_edit_tree!, only: [:create_dir]

  before_action do
    push_frontend_feature_flag(:blob_blame_info, @project)
    push_frontend_feature_flag(:highlight_js_worker, @project)
    push_frontend_feature_flag(:explain_code_chat, current_user)
    push_frontend_feature_flag(:encoding_logs_tree)
    push_licensed_feature(:file_locks) if @project.licensed_feature_available?(:file_locks)
  end

  feature_category :source_code_management
  urgency :low, [:show]

  def show
    return render_404 unless @commit

    unless Feature.enabled?(:redirect_with_ref_type, @project)
      @ref_type = ref_type
      if @ref_type == BRANCH_REF_TYPE && ambiguous_ref?(@project, @ref)
        branch = @project.repository.find_branch(@ref)
        if branch
          redirect_to project_tree_path(@project, branch.target)
          return
        end
      end
    end

    if tree.entries.empty?
      if @repository.blob_at(@commit.id, @path)
        redirect_to project_blob_path(@project, File.join(@ref, @path), ref_type: @ref_type)
      elsif @path.present?
        redirect_to_tree_root_for_missing_path(@project, @ref, @path)
      end
    end
  end

  def create_dir
    return render_404 unless @commit_params.values.all?

    create_commit(
      Files::CreateDirService,
      success_notice: _("The directory has been successfully created."),
      success_path: project_tree_path(@project, File.join(@branch_name, @dir_name)),
      failure_path: project_tree_path(@project, @ref)
    )
  end

  private

  def find_requested_ref
    return unless Feature.enabled?(:redirect_with_ref_type, @project)

    @ref_type = ref_type
    if @ref_type.present?
      @tree = @repo.tree(@ref, @path, ref_type: @ref_type)
    else
      response = ExtractsPath::RequestedRef.new(@repository, ref_type: nil, ref: @ref).find
      @ref_type = response[:ref_type]
      @commit = response[:commit]

      if response[:ambiguous]
        redirect_to(project_tree_path(@project, File.join(@ref_type ? @ref : @commit.id, @path), ref_type: @ref_type))
      end
    end
  end

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

Projects::TreeController.prepend_mod

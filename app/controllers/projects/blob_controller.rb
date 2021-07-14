# frozen_string_literal: true

# Controller for viewing a file's blame
class Projects::BlobController < Projects::ApplicationController
  include ExtractsPath
  include CreatesCommit
  include RendersBlob
  include NotesHelper
  include ActionView::Helpers::SanitizeHelper
  include RedirectsForMissingPathOnTree
  include SourcegraphDecorator
  include DiffHelper
  include RedisTracking
  extend ::Gitlab::Utils::Override

  prepend_before_action :authenticate_user!, only: [:edit]

  around_action :allow_gitaly_ref_name_caching, only: [:show]

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :authorize_download_code!

  # We need to assign the blob vars before `authorize_edit_tree!` so we can
  # validate access to a specific ref.
  before_action :assign_blob_vars

  # Since BlobController doesn't use assign_ref_vars, we have to call this explicitly
  before_action :rectify_renamed_default_branch!, only: [:show]

  before_action :authorize_edit_tree!, only: [:new, :create, :update, :destroy]

  before_action :commit, except: [:new, :create]
  before_action :blob, except: [:new, :create]
  before_action :require_branch_head, only: [:edit, :update]
  before_action :editor_variables, except: [:show, :preview, :diff]
  before_action :validate_diff_params, only: :diff
  before_action :set_last_commit_sha, only: [:edit, :update]
  before_action :track_experiment, only: :create

  track_redis_hll_event :create, :update, name: 'g_edit_by_sfe'

  feature_category :source_code_management

  before_action do
    push_frontend_feature_flag(:refactor_blob_viewer, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:consolidated_edit_button, @project, default_enabled: :yaml)
  end

  def new
    commit unless @repository.empty?
  end

  def create
    create_commit(Files::CreateService, success_notice: _("The file has been successfully created."),
                                        success_path: -> { create_success_path },
                                        failure_view: :new,
                                        failure_path: project_new_blob_path(@project, @ref))
  end

  def show
    conditionally_expand_blob(@blob)

    respond_to do |format|
      format.html do
        show_html
      end

      format.json do
        page_title @blob.path, @ref, @project.full_name

        show_json
      end
    end
  end

  def edit
    if can_collaborate_with_project?(project, ref: @ref)
      blob.load_all_data!
    else
      redirect_to action: 'show'
    end
  end

  def update
    @path = params[:file_path] if params[:file_path].present?

    create_commit(Files::UpdateService, success_path: -> { after_edit_path },
                                        failure_view: :edit,
                                        failure_path: project_blob_path(@project, @id))
  rescue Files::UpdateService::FileChangedError
    @conflict = true
    render :edit
  end

  def preview
    @content = params[:content]
    @blob.load_all_data!
    diffy = Diffy::Diff.new(@blob.data, @content, diff: '-U 3', include_diff_info: true)
    diff_lines = diffy.diff.scan(/.*\n/)[2..-1]
    diff_lines = Gitlab::Diff::Parser.new.parse(diff_lines).to_a
    @diff_lines = Gitlab::Diff::Highlight.new(diff_lines, repository: @repository).highlight

    render layout: false
  end

  def destroy
    create_commit(Files::DeleteService, success_notice: _("The file has been successfully deleted."),
                                        success_path: -> { after_delete_path },
                                        failure_path: project_blob_path(@project, @id))
  end

  def diff
    @form = Blobs::UnfoldPresenter.new(blob, diff_params)

    # keep only json rendering when
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/44988 is done
    if rendered_for_merge_request?
      render json: DiffLineSerializer.new.represent(@form.diff_lines)
    else
      @lines = @form.lines
      @match_line = @form.match_line_text
      render layout: false
    end
  end

  private

  attr_reader :branch_name

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)

    if @blob
      @blob
    else
      if tree = @repository.tree(@commit.id, @path)
        if tree.entries.any?
          return redirect_to project_tree_path(@project, File.join(@ref, @path))
        end
      end

      redirect_to_tree_root_for_missing_path(@project, @ref, @path)
    end
  end

  def commit
    @commit ||= @repository.commit(@ref)

    return render_404 unless @commit
  end

  def redirect_renamed_default_branch?
    action_name == 'show'
  end

  def assign_blob_vars
    @id = params[:id]
    @ref, @path = extract_ref(@id)
  rescue InvalidPathError
    render_404
  end

  def rectify_renamed_default_branch!
    @commit ||= @repository.commit(@ref)

    super
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def after_edit_path
    from_merge_request = MergeRequestsFinder.new(current_user, project_id: @project.id).find_by(iid: params[:from_merge_request_iid])
    if from_merge_request && @branch_name == @ref
      diffs_project_merge_request_path(from_merge_request.target_project, from_merge_request) +
        "##{hexdigest(@path)}"
    else
      project_blob_path(@project, File.join(@branch_name, @path))
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def after_delete_path
    branch = BranchesFinder.new(@repository, search: @ref).execute.first
    if @repository.tree(branch.target, tree_path).entries.empty?
      project_tree_path(@project, @ref)
    else
      project_tree_path(@project, File.join(@ref, tree_path))
    end
  end

  def editor_variables
    @branch_name = params[:branch_name]

    @file_path =
      if action_name.to_s == 'create'
        if params[:file].present?
          params[:file_name] = params[:file].original_filename
        end

        File.join(@path, params[:file_name])
      elsif params[:file_path].present?
        params[:file_path]
      else
        @path
      end

    if params[:file].present?
      params[:content] = params[:file]
    end

    @commit_params = {
      file_path: @file_path,
      commit_message: params[:commit_message],
      previous_path: @path,
      file_content: params[:content],
      file_content_encoding: params[:encoding],
      last_commit_sha: params[:last_commit_sha]
    }
  end

  def validate_diff_params
    return if params[:full]

    if [:since, :to, :offset].any? { |key| params[key].blank? }
      head :ok
    end
  end

  def set_last_commit_sha
    @last_commit_sha = Gitlab::Git::Commit
      .last_for_path(@repository, @ref, @path, literal_pathspec: true).sha
  end

  def show_html
    environment_params = @repository.branch_exists?(@ref) ? { ref: @ref } : { commit: @commit }
    environment_params[:find_latest] = true
    @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(@project, current_user, environment_params).execute.last
    @last_commit = @repository.last_commit_for_path(@commit.id, @blob.path, literal_pathspec: true)
    @code_navigation_path = Gitlab::CodeNavigationPath.new(@project, @blob.commit_id).full_json_path_for(@blob.path)

    render 'show'
  end

  def show_json
    set_last_commit_sha

    json = {
      id: @blob.id,
      last_commit_sha: @last_commit_sha,
      path: blob.path,
      name: blob.name,
      extension: blob.extension,
      size: blob.raw_size,
      mime_type: blob.mime_type,
      binary: blob.binary?,
      simple_viewer: blob.simple_viewer&.class&.partial_name,
      rich_viewer: blob.rich_viewer&.class&.partial_name,
      show_viewer_switcher: !!blob.show_viewer_switcher?,
      render_error: blob.simple_viewer&.render_error || blob.rich_viewer&.render_error,
      raw_path: project_raw_path(project, @id),
      blame_path: project_blame_path(project, @id),
      commits_path: project_commits_path(project, @id),
      tree_path: project_tree_path(project, File.join(@ref, tree_path)),
      permalink: project_blob_path(project, File.join(@commit.id, @path))
    }

    json.merge!(blob_json(@blob) || {}) unless params[:viewer] == 'none'

    render json: json
  end

  def tree_path
    @path.rpartition('/').first
  end

  def diff_params
    params.permit(:full, :since, :to, :bottom, :unfold, :offset, :indent)
  end

  override :visitor_id
  def visitor_id
    current_user&.id
  end

  def create_success_path
    if params[:code_quality_walkthrough]
      project_pipelines_path(@project, code_quality_walkthrough: true)
    else
      project_blob_path(@project, File.join(@branch_name, @file_path))
    end
  end

  def track_experiment
    return unless params[:code_quality_walkthrough]

    experiment(:code_quality_walkthrough, namespace: @project.root_ancestor).track(:commit_created)
  end
end

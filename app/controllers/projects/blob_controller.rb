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
  include ProductAnalyticsTracking
  extend ::Gitlab::Utils::Override

  prepend_before_action :authenticate_user!, only: [:edit]

  around_action :allow_gitaly_ref_name_caching, only: [:show]

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :authorize_download_code!, except: [:show]
  before_action :authorize_read_code!, only: [:show]

  # We need to assign the blob vars before `authorize_edit_tree!` so we can
  # validate access to a specific ref.
  before_action :assign_blob_vars, except: [:show]
  before_action :assign_ref_vars, only: [:show]

  before_action :authorize_edit_tree!, only: [:new, :create, :update, :destroy]

  before_action :require_commit, except: [:new, :create]
  before_action :set_is_ambiguous_ref, only: [:show]
  before_action :check_for_ambiguous_ref, only: [:show]
  before_action :require_blob, except: [:new, :create]
  before_action :require_branch_head, only: [:edit, :update]
  before_action :editor_variables, except: [:show, :preview, :diff]
  before_action :validate_diff_params, only: :diff

  before_action :set_last_commit_sha, only: [:edit, :update]

  track_internal_event :create, :update, name: 'g_edit_by_sfe'

  feature_category :source_code_management
  urgency :low, [:create, :show, :edit, :update, :diff, :diff_lines]

  before_action do
    push_frontend_feature_flag(:inline_blame, @project)
    push_frontend_feature_flag(:blob_overflow_menu, current_user)
    push_frontend_feature_flag(:blob_repository_vue_header_app, @project)
    push_licensed_feature(:file_locks) if @project.licensed_feature_available?(:file_locks)
  end

  def new
    commit unless @repository.empty?
  end

  def create
    create_commit(
      Files::CreateService,
      success_notice: _("The file has been successfully created."),
      success_path: -> { project_blob_path(@project, File.join(@branch_name, @file_path)) },
      failure_view: :new,
      failure_path: project_new_blob_path(@project, @ref)
    )
  end

  def show
    conditionally_expand_blob(blob)

    respond_to do |format|
      format.html do
        show_html
      end

      format.json do
        page_title blob.path, @ref, @project.full_name
        set_last_commit_sha
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

    create_commit(
      Files::UpdateService, success_path: -> { after_edit_path },
      failure_view: :edit,
      failure_path: project_blob_path(@project, @id)
    )
  rescue Files::UpdateService::FileChangedError
    @conflict = true
    render "edit", locals: {
      commit_to_fork: @different_project
    }
  end

  def preview
    @content = params[:content]
    blob.load_all_data!
    diffy = Diffy::Diff.new(blob.data, @content, diff: '-U 3', include_diff_info: true)
    diff_lines = diffy.diff.scan(/.*\n/)[2..]
    diff_lines = Gitlab::Diff::Parser.new.parse(diff_lines).to_a
    @diff_lines = Gitlab::Diff::Highlight.new(diff_lines, repository: @repository).highlight

    render layout: false
  end

  def destroy
    create_commit(
      Files::DeleteService,
      success_notice: _("The file has been successfully deleted."),
      success_path: -> { after_delete_path },
      failure_path: project_blob_path(@project, @id)
    )
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

  def diff_lines
    return render_404 unless rapid_diffs_enabled?

    params.require([:since, :to, :offset])

    bottom = diff_lines_params[:bottom] == 'true'
    closest_line_number = diff_lines_params[:closest_line_number]&.to_i

    presenter = Blobs::UnfoldPresenter.new(blob, diff_params.merge({ unfold: !!closest_line_number }))
    diff_hunks = Gitlab::Diff::ViewerHunk.init_from_expanded_lines(
      presenter.diff_lines(with_positions_and_indent: true),
      bottom,
      closest_line_number
    )
    return render_404 if diff_hunks.empty?

    hunk_presenter = if diff_view == :inline
                       RapidDiffs::Viewers::Text::InlineHunkComponent
                     else
                       RapidDiffs::Viewers::Text::ParallelHunkComponent
                     end

    render hunk_presenter.with_collection(
      diff_hunks,
      file_hash: blob.file_hash,
      file_path: blob.path
    ), layout: false
  end

  private

  attr_reader :branch_name

  def rapid_diffs_enabled?
    ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)
  end

  def blob
    return unless commit

    @blob = @repository.blob_at(commit.id, @path)
  end
  strong_memoize_attr :blob

  def require_blob
    redirect_to_project_tree_path unless blob
  end

  def redirect_to_project_tree_path
    if @repository.tree(commit.id, @path).entries.any?
      return redirect_to(project_tree_path(@project, File.join(@ref, @path)))
    end

    redirect_to_tree_root_for_missing_path(@project, @ref, @path)
  end

  def check_for_ambiguous_ref
    @ref_type = ref_type
  end

  def commit
    @commit = @repository.commit(@ref)
  end
  strong_memoize_attr :commit

  def require_commit
    render_404 unless commit
  end

  def redirect_renamed_default_branch?
    action_name == 'show'
  end

  def assign_blob_vars
    ref_extractor = ExtractsRef::RefExtractor.new(@project, {})
    @id = params[:id]

    @ref, @path = ref_extractor.extract_ref(@id)
  rescue InvalidPathError
    render_404
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def after_edit_path
    from_merge_request = MergeRequestsFinder.new(
      current_user,
      project_id: @project.id
    ).find_by(iid: params[:from_merge_request_iid])

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

    @file_path = fetch_file_path

    params[:content] = params[:file] if params[:file].present?

    @commit_params = {
      file_path: @file_path,
      commit_message: params[:commit_message],
      previous_path: @path,
      file_content: params[:content],
      file_content_encoding: params[:encoding],
      last_commit_sha: params[:last_commit_sha]
    }
  end

  def fetch_file_path
    file_params = params.permit(:file, :file_name, :file_path)

    if action_name.to_s == 'create'
      file_name = file_params[:file].present? ? file_params[:file].original_filename : file_params[:file_name]

      return if file_name.nil?

      return File.join(@path, file_name)
    end

    return file_params[:file_path] if file_params[:file_path].present?

    @path
  end

  def validate_diff_params
    return if params[:full]

    head :ok if [:since, :to, :offset].any? { |key| params[key].blank? }
  end

  def set_last_commit_sha
    @last_commit_sha = Gitlab::Git::Commit
      .last_for_path(@repository, @ref, @path, literal_pathspec: true).sha
  end

  def show_html
    environment_params = @repository.branch_exists?(@ref) ? { ref: @ref } : { commit: commit }
    environment_params[:find_latest] = true
    @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(
      @project,
      current_user,
      environment_params
    ).execute.last
    @last_commit = @repository.last_commit_for_path(commit.id, blob.path, literal_pathspec: true)
    @code_navigation_path = Gitlab::CodeNavigationPath.new(@project, blob.commit_id).full_json_path_for(blob.path)

    render 'show'
  end

  def show_json
    json = blob_viewer_json(blob).merge(
      id: blob.id,
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
      permalink: project_blob_path(project, File.join(commit.id, @path))
    )

    render json: json
  end

  def tree_path
    @path.rpartition('/').first
  end

  def diff_params
    params.permit(:full, :since, :to, :bottom, :unfold, :offset, :indent)
  end

  def diff_lines_params
    params.permit(:full, :bottom, :since, :to, :offset, :closest_line_number)
  end

  override :visitor_id
  def visitor_id
    current_user&.id
  end

  alias_method :tracking_project_source, :project

  def tracking_namespace_source
    project&.namespace
  end
end

Projects::BlobController.prepend_mod

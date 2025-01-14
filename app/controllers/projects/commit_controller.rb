# frozen_string_literal: true

# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class Projects::CommitController < Projects::ApplicationController
  include RendersNotes
  include CreatesCommit
  include DiffForPath
  include DiffHelper
  include SourcegraphDecorator
  include DiffsStreamResource

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_read_code!
  before_action :authorize_read_pipeline!, only: [:pipelines]
  before_action :commit
  before_action :define_commit_vars,
    only: [:show, :diff_for_path, :diff_files, :pipelines, :merge_requests, :rapid_diffs]
  before_action :define_commit_box_vars, only: [:show, :pipelines, :rapid_diffs]
  before_action :define_note_vars, only: [:show, :diff_for_path, :diff_files]
  before_action :authorize_edit_tree!, only: [:revert, :cherry_pick]
  before_action :rate_limit_for_expanded_diff_files, only: :diff_files

  BRANCH_SEARCH_LIMIT = 1000
  COMMIT_DIFFS_PER_PAGE = 20

  feature_category :source_code_management
  urgency :low, [:pipelines, :merge_requests, :show, :rapid_diffs]

  def show
    apply_diff_view_cookie!

    respond_to do |format|
      format.html do
        @ref = params[:id]
        render locals: { pagination_params: params.permit(:page) }
      end
      format.diff do
        send_git_diff(@project.repository, @commit.diff_refs)
      end
      format.patch do
        send_git_patch(@project.repository, @commit.diff_refs)
      end
    end
  end

  def diff_for_path
    render_diff_for_path(@commit.diffs(diff_options))
  end

  def diff_files
    respond_to do |format|
      format.html do
        render template: 'projects/commit/diff_files',
          layout: false,
          locals: {
            diffs: diffs_expanded? ? @diffs.with_highlights_preloaded : @diffs,
            environment: @environment
          }
      end
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def pipelines
    @pipelines = @commit.pipelines.order(id: :desc)
    @pipelines = @pipelines.where(ref: params[:ref]) if params[:ref]
    @pipelines = @pipelines.page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: {
          pipelines: PipelineSerializer
            .new(project: @project, current_user: @current_user)
            .with_pagination(request, response)
            .represent(@pipelines),
          count: {
            all: @pipelines.count
          }
        }
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def merge_requests
    @merge_requests = MergeRequestsFinder.new(
      current_user,
      project_id: @project.id,
      commit_sha: @commit.sha
    ).execute.map do |mr|
      { iid: mr.iid, path: merge_request_path(mr), title: mr.title }
    end

    respond_to do |format|
      format.json do
        render json: Gitlab::Json.dump(@merge_requests)
      end
    end
  end

  def branches
    return git_not_found! unless commit

    # branch_names_contains/tag_names_contains can take a long time when there are thousands of
    # branches/tags - each `git branch --contains xxx` request can consume a cpu core.
    # so only do the query when there are a manageable number of branches/tags
    @branches_limit_exceeded = @project.repository.branch_count > BRANCH_SEARCH_LIMIT
    @branches = @branches_limit_exceeded ? [] : @project.repository.branch_names_contains(commit.id)

    @tags_limit_exceeded = @project.repository.tag_count > BRANCH_SEARCH_LIMIT
    @tags = @tags_limit_exceeded ? [] : @project.repository.tag_names_contains(commit.id)
    render layout: false
  end

  def revert
    return render_404 unless @commit

    assign_change_commit_vars

    return render_404 if @start_branch.blank?

    @branch_name = create_new_branch? ? @commit.revert_branch_name : @start_branch

    create_commit(
      Commits::RevertService,
      success_notice: "The #{@commit.change_type_title(current_user)} has been successfully reverted.",
      success_path: -> { successful_change_path(@project) },
      failure_path: failed_change_path
    )
  end

  def cherry_pick
    return render_404 unless @commit

    assign_change_commit_vars

    return render_404 if @start_branch.blank?

    target_project = find_cherry_pick_target_project
    return render_404 unless target_project

    @branch_name = create_new_branch? ? @commit.cherry_pick_branch_name : @start_branch

    create_commit(
      Commits::CherryPickService,
      success_notice: "The #{@commit.change_type_title(current_user)} has been successfully " \
        "cherry-picked into #{@branch_name}.",
      success_path: -> { successful_change_path(target_project) },
      failure_path: failed_change_path,
      target_project: target_project
    )
  end

  def rapid_diffs
    return render_404 unless ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)

    streaming_offset = 5
    @stream_url = diffs_stream_url(@commit, streaming_offset, diff_view)
    @diffs_slice = @commit.first_diffs_slice(streaming_offset, commit_diff_options)

    show
  end

  private

  def commit_diff_options
    opts = diff_options
    opts[:ignore_whitespace_change] = true if params[:format] == 'diff'
    opts[:use_extra_viewer_as_main] = false
    opts
  end

  def create_new_branch?
    params[:create_merge_request].present? || !can?(current_user, :push_code, @project)
  end

  def successful_change_path(target_project)
    referenced_merge_request_url || project_commits_url(target_project, @branch_name)
  end

  def failed_change_path
    referenced_merge_request_url || project_commit_url(@project, params[:id])
  end

  def referenced_merge_request_url
    if merge_request = @commit.merged_merge_request(current_user)
      project_merge_request_url(merge_request.target_project, merge_request)
    end
  end

  def commit
    @noteable = @commit ||= @project.commit_by(oid: params[:id]).tap do |commit|
      # preload author and their status for rendering
      commit&.author&.status
    end
  end

  def define_commit_vars
    return git_not_found! unless commit

    @diffs = commit.diffs(commit_diff_options)
    @environment = ::Environments::EnvironmentsByDeploymentsFinder.new(
      @project,
      current_user,
      commit: @commit,
      find_latest: true
    ).execute.last
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def define_note_vars
    @noteable = @commit
    @note = @project.build_commit_note(commit)

    @new_diff_note_attrs = {
      noteable_type: 'Commit',
      commit_id: @commit.id
    }

    @grouped_diff_discussions = commit.grouped_diff_discussions
    @discussions = commit.discussions

    if merge_request_iid = params[:merge_request_iid]
      @merge_request = MergeRequestsFinder.new(current_user, project_id: @project.id).find_by(iid: merge_request_iid)

      if @merge_request
        @new_diff_note_attrs.merge!(
          noteable_type: 'MergeRequest',
          noteable_id: @merge_request.id
        )

        merge_request_commit_notes = @merge_request.notes.where(commit_id: @commit.id).inc_relations_for_view
        merge_request_commit_diff_discussions = merge_request_commit_notes.grouped_diff_discussions(@commit.diff_refs)
        @grouped_diff_discussions.merge!(merge_request_commit_diff_discussions) do |line_code, left, right|
          left + right
        end
      end
    end

    @notes = (@grouped_diff_discussions.values.flatten + @discussions).flat_map(&:notes)
    @notes = prepare_notes_for_rendering(@notes)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def define_commit_box_vars
    @last_pipeline = @commit.last_pipeline

    return unless @commit.last_pipeline

    @last_pipeline_stages = StageSerializer.new(
      project: @project,
      current_user: @current_user
    ).represent(@last_pipeline.stages)
  end

  def assign_change_commit_vars
    @start_branch = params[:start_branch]
    @commit_params = { commit: @commit }
  end

  def find_cherry_pick_target_project
    return @project if params[:target_project_id].blank?

    MergeRequestTargetProjectFinder
      .new(current_user: current_user, source_project: @project, project_feature: :repository)
      .execute
      .find_by_id(params[:target_project_id])
  end

  def append_info_to_payload(payload)
    super

    return unless action_name == 'show' && @diffs.present?

    payload[:metadata] ||= {}
    payload[:metadata]['meta.diffs_files_count'] = @diffs.size
  end

  def diffs_stream_resource_url(commit, offset, diff_view)
    diffs_stream_namespace_project_commit_path(
      namespace_id: commit.project.namespace.to_param,
      project_id: commit.project.to_param,
      id: commit.id,
      offset: offset,
      view: diff_view
    )
  end

  def rate_limit_for_expanded_diff_files
    return unless diffs_expanded?

    check_rate_limit!(:expanded_diff_files, scope: current_user || request.ip)
  end
end

Projects::CommitController.prepend_mod_with('Projects::CommitController')

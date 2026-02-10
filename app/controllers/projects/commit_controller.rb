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
  include RapidDiffs::Resource
  include RapidDiffs::DiscussionActions

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_read_code!
  before_action :authorize_read_pipeline!, only: [:pipelines]
  before_action :commit
  before_action :verify_commit, only: [:show, :diff_for_path, :diff_files, :pipelines, :merge_requests]
  before_action :define_commit_vars, only: [:diff_for_path, :diff_files, :pipelines, :merge_requests]
  before_action :define_environment,
    only: [:show, :diff_for_path, :diff_files, :pipelines, :merge_requests]
  before_action :define_commit_box_vars, only: [:show, :pipelines]
  before_action :define_note_vars, only: [:diff_for_path, :diff_files, :discussions, :create_discussions]
  before_action :authorize_edit_tree!, only: [:revert, :cherry_pick]
  before_action :rate_limit_for_expanded_diff_files, only: :diff_files

  BRANCH_SEARCH_LIMIT = 1000
  COMMIT_DIFFS_PER_PAGE = 20

  feature_category :source_code_management
  urgency :low, [:pipelines, :merge_requests, :show]

  helper_method :rapid_diffs_presenter

  def show
    apply_diff_view_cookie!

    respond_to do |format|
      format.html do
        if rapid_diffs_enabled? && !rapid_diffs_force_disabled?
          @js_action_name = 'rapid_diffs'
          render action: :rapid_diffs
        else
          define_commit_vars
          define_note_vars
          @ref = commit_params_safe[:id]
          render locals: { pagination_params: pagination_params }
        end
      end
      format.diff do
        send_git_diff(@project.repository, @commit.diff_refs)
      end
      format.patch do
        send_git_patch(@project.repository, @commit.diff_refs)
      end
    end
  end

  def discussions
    return render_404 unless rapid_diffs_enabled?

    all_discussions = (@grouped_diff_discussions.values.flatten + @discussions)

    all_notes = all_discussions.flat_map(&:notes)
    prepare_notes_for_rendering(all_notes)

    serialized_discussions = RapidDiffs::DiscussionSerializer.new(
      project: @project,
      noteable: @commit,
      current_user: current_user,
      note_entity: RapidDiffs::NoteEntity
    ).represent(all_discussions)

    render json: { discussions: serialized_discussions }
  end

  def create_discussions
    create_discussions_for_resource
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
    @pipelines = @pipelines.where(ref: commit_params_safe[:ref]) if commit_params_safe[:ref]
    # Capture total count before pagination to ensure accurate count regardless of current page
    @pipelines_count = @pipelines.count
    @pipelines = @pipelines.page(pagination_params[:page])

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
            all: @pipelines_count
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

  def revert
    return render_404 unless @commit

    assign_change_commit_vars
    @commit_params[:revert] = true

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

  private

  def rapid_diffs_presenter
    return if @commit.nil?

    @rapid_diffs_presenter ||= RapidDiffs::CommitPresenter.new(
      @commit,
      diff_view: diff_view,
      diff_options: commit_diff_options,
      request_params: params,
      current_user: current_user,
      environment: define_environment
    )
  end

  def rapid_diffs_enabled?
    ::Feature.enabled?(:rapid_diffs_on_commit_show, current_user, type: :beta)
  end

  def rapid_diffs_force_disabled?
    ::Feature.enabled?(:rapid_diffs_debug, current_user, type: :ops) &&
      params.permit(:rapid_diffs_disabled)[:rapid_diffs_disabled] == 'true'
  end

  def noteable
    @commit
  end

  def noteable_params
    {
      noteable_type: 'Commit',
      commit_id: @commit.id
    }
  end

  def grouped_discussions
    @grouped_diff_discussions
  end

  def timeline_discussions
    @discussions
  end

  def create_note_params
    params.require(:note).permit(
      :type,
      :note,
      position: [:old_path, :new_path, :old_line, :new_line, :position_type, :x, :y, :width, :height]
    ).tap do |create_params|
      enrich_note_params(create_params, params[:in_reply_to_discussion_id])
    end
  end

  def enrich_note_params(create_params, in_reply_to_discussion_id)
    if in_reply_to_discussion_id.present?
      create_params[:in_reply_to_discussion_id] = in_reply_to_discussion_id
    elsif create_params[:position].present?
      create_params[:position][:old_line] = create_params[:position][:old_line]&.to_i.presence
      create_params[:position][:new_line] = create_params[:position][:new_line]&.to_i.presence
      create_params[:type] = 'DiffNote' if create_params[:type].blank?
      create_params[:position][:position_type] = 'text' unless create_params[:position][:position_type].present?
      create_params[:position] = enrich_position_data(create_params[:position])
    end

    create_params[:type] = 'DiscussionNote' if create_params[:type].blank?

    create_params.merge!(noteable_params)
  end

  def enrich_position_data(position_data)
    position = position_data.to_h

    position.reverse_merge!(
      'base_sha' => noteable.diff_refs.base_sha,
      'start_sha' => noteable.diff_refs.start_sha,
      'head_sha' => noteable.diff_refs.head_sha
    )

    position
  end

  def pagination_params
    params.permit(:page)
  end

  def commit_params_safe
    params.permit(:id, :start_branch, :create_merge_request, :merge_request_iid, :target_project_id, :ref)
  end

  def commit_diff_options
    opts = diff_options
    opts[:ignore_whitespace_change] = true if params[:format] == 'diff'
    opts[:use_extra_viewer_as_main] = false
    opts
  end

  def create_new_branch?
    commit_params_safe[:create_merge_request].present? || !can?(current_user, :push_code, @project)
  end

  def successful_change_path(target_project)
    referenced_merge_request_url || project_commits_url(target_project, @branch_name)
  end

  def failed_change_path
    referenced_merge_request_url || project_commit_url(@project, commit_params_safe[:id])
  end

  def referenced_merge_request_url
    if merge_request = @commit.merged_merge_request(current_user)
      project_merge_request_url(merge_request.target_project, merge_request)
    end
  end

  def commit
    @noteable = @commit ||= @project.commit_by(oid: commit_params_safe[:id]).tap do |commit|
      # preload author and their status for rendering
      commit&.author&.status
    end
  end

  def verify_commit
    git_not_found! unless commit
  end

  def define_commit_vars
    @diffs = commit.diffs(commit_diff_options)
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

    if merge_request_iid = commit_params_safe[:merge_request_iid]
      @merge_request = MergeRequestsFinder.new(current_user, project_id: @project.id).find_by(iid: merge_request_iid)

      if @merge_request
        @new_diff_note_attrs.merge!(
          noteable_type: 'MergeRequest',
          noteable_id: @merge_request.id
        )

        merge_request_commit_notes = @merge_request.notes.where(commit_id: @commit.id).inc_relations_for_view
        merge_request_commit_diff_discussions = merge_request_commit_notes.grouped_diff_discussions(@commit.diff_refs)
        @grouped_diff_discussions.merge!(merge_request_commit_diff_discussions) do |_line_code, left, right|
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
    @start_branch = commit_params_safe[:start_branch]
    @commit_params = { commit: @commit }
  end

  def find_cherry_pick_target_project
    return @project if commit_params_safe[:target_project_id].blank?

    MergeRequestTargetProjectFinder
      .new(current_user: current_user, source_project: @project, project_feature: :repository)
      .execute
      .find_by_id(commit_params_safe[:target_project_id])
  end

  def rate_limit_for_expanded_diff_files
    return unless diffs_expanded?

    check_rate_limit!(:expanded_diff_files, scope: current_user || request.ip)
  end

  def complete_diff_path
    project_commit_path(project, commit, format: :diff)
  end

  def email_format_path
    project_commit_path(project, commit, format: :patch)
  end

  def define_environment
    @environment ||= ::Environments::EnvironmentsByDeploymentsFinder.new(
      @project,
      current_user,
      commit: @commit,
      find_latest: true
    ).execute.last
  end
end

Projects::CommitController.prepend_mod_with('Projects::CommitController')

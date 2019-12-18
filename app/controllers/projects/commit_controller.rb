# frozen_string_literal: true

# Controller for a specific Commit
#
# Not to be confused with CommitsController, plural.
class Projects::CommitController < Projects::ApplicationController
  include RendersNotes
  include CreatesCommit
  include DiffForPath
  include DiffHelper
  include SourcegraphGon

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_read_pipeline!, only: [:pipelines]
  before_action :commit
  before_action :define_commit_vars, only: [:show, :diff_for_path, :pipelines, :merge_requests]
  before_action :define_note_vars, only: [:show, :diff_for_path]
  before_action :authorize_edit_tree!, only: [:revert, :cherry_pick]

  BRANCH_SEARCH_LIMIT = 1000

  def show
    apply_diff_view_cookie!

    respond_to do |format|
      format.html do
        render
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

  # rubocop: disable CodeReuse/ActiveRecord
  def pipelines
    @pipelines = @commit.pipelines.order(id: :desc)
    @pipelines = @pipelines.where(ref: params[:ref]).page(params[:page]).per(30) if params[:ref]

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
        render json: @merge_requests.to_json
      end
    end
  end

  def branches
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
    assign_change_commit_vars

    return render_404 if @start_branch.blank?

    @branch_name = create_new_branch? ? @commit.revert_branch_name : @start_branch

    create_commit(Commits::RevertService, success_notice: "The #{@commit.change_type_title(current_user)} has been successfully reverted.",
                                          success_path: -> { successful_change_path }, failure_path: failed_change_path)
  end

  def cherry_pick
    assign_change_commit_vars

    return render_404 if @start_branch.blank?

    @branch_name = create_new_branch? ? @commit.cherry_pick_branch_name : @start_branch

    create_commit(Commits::CherryPickService, success_notice: "The #{@commit.change_type_title(current_user)} has been successfully cherry-picked into #{@branch_name}.",
                                              success_path: -> { successful_change_path }, failure_path: failed_change_path)
  end

  private

  def create_new_branch?
    params[:create_merge_request].present? || !can?(current_user, :push_code, @project)
  end

  def successful_change_path
    referenced_merge_request_url || project_commits_url(@project, @branch_name)
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

    opts = diff_options
    opts[:ignore_whitespace_change] = true if params[:format] == 'diff'

    @diffs = commit.diffs(opts)
    @notes_count = commit.notes.count

    @environment = EnvironmentsFinder.new(@project, current_user, commit: @commit, find_latest: true).execute.last
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
    @notes = prepare_notes_for_rendering(@notes, @commit)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def assign_change_commit_vars
    @start_branch = params[:start_branch]
    @commit_params = { commit: @commit }
  end
end

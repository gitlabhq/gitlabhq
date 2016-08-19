class Projects::MergeRequestsController < Projects::ApplicationController
  include ToggleSubscriptionAction
  include DiffForPath
  include DiffHelper
  include IssuableActions
  include NotesHelper
  include ToggleAwardEmoji
  include IssuableCollections

  before_action :module_enabled
  before_action :merge_request, only: [
    :edit, :update, :show, :diffs, :commits, :builds, :merge, :merge_check,
    :ci_status, :toggle_subscription, :cancel_merge_when_build_succeeds, :remove_wip,
    :approve, :rebase
  ]
  before_action :validates_merge_request, only: [:show, :diffs, :commits, :builds]
  before_action :define_show_vars, only: [:show, :diffs, :commits, :builds]
  before_action :define_widget_vars, only: [:merge, :cancel_merge_when_build_succeeds, :merge_check]
  before_action :define_commit_vars, only: [:diffs]
  before_action :define_diff_comment_vars, only: [:diffs]
  before_action :ensure_ref_fetched, only: [:show, :diffs, :commits, :builds]

  # Allow read any merge_request
  before_action :authorize_read_merge_request!

  # Allow write(create) merge_request
  before_action :authorize_create_merge_request!, only: [:new, :create]

  # Allow modify merge_request
  before_action :authorize_update_merge_request!, only: [:close, :edit, :update, :remove_wip, :sort]

  def index
    terms = params['issue_search']
    @merge_requests = merge_requests_collection

    if terms.present?
      if terms =~ /\A[#!](\d+)\z/
        @merge_requests = @merge_requests.where(iid: $1)
      else
        @merge_requests = @merge_requests.full_search(terms)
      end
    end

    @merge_requests = @merge_requests.page(params[:page])
    @merge_requests = @merge_requests.preload(:target_project)

    @labels = @project.labels.where(title: params[:label_name])

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("projects/merge_requests/_merge_requests"),
          labels: @labels.as_json(methods: :text_color)
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { define_discussion_vars }

      format.json do
        render json: @merge_request, methods: :rebase_in_progress?
      end

      format.patch  do
        return render_404 unless @merge_request.diff_refs

        send_git_patch @project.repository, @merge_request.diff_refs
      end

      format.diff do
        return render_404 unless @merge_request.diff_refs

        send_git_diff @project.repository, @merge_request.diff_refs
      end
    end
  end

  def diffs
    apply_diff_view_cookie!

    @merge_request_diff = @merge_request.merge_request_diff

    respond_to do |format|
      format.html { define_discussion_vars }
      format.json do
        @diffs = @merge_request.diffs(diff_options)

        render json: { html: view_to_html_string("projects/merge_requests/show/_diffs") }
      end
    end
  end

  # With an ID param, loads the MR at that ID. Otherwise, accepts the same params as #new
  # and uses that (unsaved) MR.
  #
  def diff_for_path
    if params[:id]
      merge_request
      define_diff_comment_vars
    else
      build_merge_request
      @diff_notes_disabled = true
      @grouped_diff_discussions = {}
    end

    define_commit_vars

    render_diff_for_path(@merge_request.diffs(diff_options))
  end

  def commits
    respond_to do |format|
      format.html do
        define_discussion_vars

        render 'show'
      end
      format.json do
        # Get commits from repository
        # or from cache if already merged
        @commits = @merge_request.commits
        @note_counts = Note.where(commit_id: @commits.map(&:id)).
          group(:commit_id).count

        render json: { html: view_to_html_string('projects/merge_requests/show/_commits') }
      end
    end
  end

  def builds
    respond_to do |format|
      format.html do
        define_discussion_vars

        render 'show'
      end
      format.json { render json: { html: view_to_html_string('projects/merge_requests/show/_builds') } }
    end
  end

  def new
    build_merge_request
    @noteable = @merge_request

    @target_branches = if @merge_request.target_project
                         @merge_request.target_project.repository.branch_names
                       else
                         []
                       end

    @target_project = merge_request.target_project
    @source_project = merge_request.source_project
    @commits = @merge_request.compare_commits.reverse
    @commit = @merge_request.diff_head_commit
    @base_commit = @merge_request.diff_base_commit
    @diffs = @merge_request.diffs(diff_options) if @merge_request.compare
    @diff_notes_disabled = true

    @pipeline = @merge_request.pipeline
    @statuses = @pipeline.statuses.relevant if @pipeline

    @note_counts = Note.where(commit_id: @commits.map(&:id)).
      group(:commit_id).count

    set_suggested_approvers
  end

  def create
    @target_branches ||= []
    create_params = clamp_approvals_before_merge(merge_request_params)

    @merge_request = MergeRequests::CreateService.new(project, current_user, create_params).execute

    if @merge_request.valid?
      redirect_to(merge_request_path(@merge_request))
    else
      @source_project = @merge_request.source_project
      @target_project = @merge_request.target_project
      set_suggested_approvers

      render action: "new"
    end
  end

  def edit
    @source_project = @merge_request.source_project
    @target_project = @merge_request.target_project
    @target_branches = @merge_request.target_project.repository.branch_names

    set_suggested_approvers
  end

  def update
    update_params = clamp_approvals_before_merge(merge_request_params)

    @merge_request = MergeRequests::UpdateService.new(project, current_user, update_params).execute(@merge_request)

    if @merge_request.valid?
      respond_to do |format|
        format.html do
          redirect_to([@merge_request.target_project.namespace.becomes(Namespace),
                       @merge_request.target_project, @merge_request])
        end
        format.json do
          render json: @merge_request.to_json(include: { milestone: {}, assignee: { methods: :avatar_url }, labels: { methods: :text_color } })
        end
      end
    else
      set_suggested_approvers

      render "edit"
    end
  end

  def remove_wip
    MergeRequests::UpdateService.new(project, current_user, title: @merge_request.wipless_title).execute(@merge_request)

    redirect_to namespace_project_merge_request_path(@project.namespace, @project, @merge_request),
      notice: "The merge request can now be merged."
  end

  def merge_check
    @merge_request.check_if_can_be_merged

    render partial: "projects/merge_requests/widget/show.html.haml", layout: false
  end

  def cancel_merge_when_build_succeeds
    return access_denied! unless @merge_request.can_cancel_merge_when_build_succeeds?(current_user)

    MergeRequests::MergeWhenBuildSucceedsService.new(@project, current_user).cancel(@merge_request)
  end

  def merge
    return access_denied! unless @merge_request.can_be_merged_by?(current_user)
    return render_404 unless @merge_request.approved?

    # Disable the CI check if merge_when_build_succeeds is enabled since we have
    # to wait until CI completes to know
    unless @merge_request.mergeable?(skip_ci_check: merge_when_build_succeeds_active?)
      @status = :failed
      return
    end

    merge_request_service = MergeRequests::MergeService.new(@project, current_user, merge_params)

    unless merge_request_service.hooks_validation_pass?(@merge_request)
      @status = :hook_validation_error
      return
    end

    if params[:sha] != @merge_request.diff_head_sha
      @status = :sha_mismatch
      return
    end

    TodoService.new.merge_merge_request(merge_request, current_user)

    @merge_request.update(merge_error: nil)

    if params[:merge_when_build_succeeds].present?
      unless @merge_request.pipeline
        @status = :failed
        return
      end

      if @merge_request.pipeline.active?
        MergeRequests::MergeWhenBuildSucceedsService.new(@project, current_user, merge_params)
                                                        .execute(@merge_request)
        @status = :merge_when_build_succeeds
      elsif @merge_request.pipeline.success?
        # This can be triggered when a user clicks the auto merge button while
        # the tests finish at about the same time
        MergeWorker.perform_async(@merge_request.id, current_user.id, params)
        @status = :success
      else
        @status = :failed
      end
    else
      MergeWorker.perform_async(@merge_request.id, current_user.id, params)
      @status = :success
    end
  end

  def rebase
    return access_denied! unless @merge_request.can_be_merged_by?(current_user)
    return render_404 unless @merge_request.approved?

    RebaseWorker.perform_async(@merge_request.id, current_user.id)
  end

  def branch_from
    # This is always source
    @source_project = @merge_request.nil? ? @project : @merge_request.source_project
    @commit = @repository.commit(params[:ref]) if params[:ref].present?
    render layout: false
  end

  def branch_to
    @target_project = selected_target_project
    @commit = @target_project.commit(params[:ref]) if params[:ref].present?
    render layout: false
  end

  def update_branches
    @target_project = selected_target_project
    @target_branches = @target_project.repository.branch_names

    render layout: false
  end

  def ci_status
    pipeline = @merge_request.pipeline
    if pipeline
      status = pipeline.status
      coverage = pipeline.try(:coverage)

      status = "success_with_warnings" if pipeline.success? && pipeline.has_warnings?

      status ||= "preparing"
    else
      ci_service = @merge_request.source_project.ci_service
      status = ci_service.commit_status(merge_request.diff_head_sha, merge_request.source_branch) if ci_service

      if ci_service.respond_to?(:commit_coverage)
        coverage = ci_service.commit_coverage(merge_request.diff_head_sha, merge_request.source_branch)
      end
    end

    response = {
      title: merge_request.title,
      sha: merge_request.diff_head_commit.short_id,
      status: status,
      coverage: coverage
    }

    render json: response
  end

  def approve
    unless @merge_request.can_approve?(current_user)
      return render_404
    end

    MergeRequests::ApprovalService.
      new(project, current_user).
      execute(@merge_request)

    redirect_to merge_request_path(@merge_request)
  end

  protected

  def selected_target_project
    if @project.id.to_s == params[:target_project_id] || @project.forked_project_link.nil?
      @project
    else
      @project.forked_project_link.forked_from_project
    end
  end

  def merge_request
    @merge_request ||= @project.merge_requests.find_by!(iid: params[:id])
  end
  alias_method :subscribable_resource, :merge_request
  alias_method :issuable, :merge_request
  alias_method :awardable, :merge_request

  def authorize_update_merge_request!
    return render_404 unless can?(current_user, :update_merge_request, @merge_request)
  end

  def authorize_admin_merge_request!
    return render_404 unless can?(current_user, :admin_merge_request, @merge_request)
  end

  def module_enabled
    return render_404 unless @project.merge_requests_enabled
  end

  def validates_merge_request
    # If source project was removed (Ex. mr from fork to origin)
    return invalid_mr unless @merge_request.source_project

    # Show git not found page
    # if there is no saved commits between source & target branch
    if @merge_request.commits.blank?
      # and if target branch doesn't exist
      return invalid_mr unless @merge_request.target_branch_exists?

      # or if source branch doesn't exist
      return invalid_mr unless @merge_request.source_branch_exists?
    end
  end

  def define_show_vars
    @noteable = @merge_request
    @commits_count = @merge_request.commits.count

    @pipeline = @merge_request.pipeline
    @statuses = @pipeline.statuses.relevant if @pipeline

    if @merge_request.locked_long_ago?
      @merge_request.unlock_mr
      @merge_request.close
    end
  end

  # Discussion tab data is rendered on html responses of actions
  # :show, :diff, :commits, :builds. but not when request the data through AJAX
  def define_discussion_vars
    # Build a note object for comment form
    @note = @project.notes.new(noteable: @noteable)

    @discussions = @noteable.mr_and_commit_notes.
      inc_author_project_award_emoji.
      fresh.
      discussions

    preload_noteable_for_regular_notes(@discussions.flat_map(&:notes))

    # This is not executed lazily
    @notes = Banzai::NoteRenderer.render(
      @discussions.flat_map(&:notes),
      @project,
      current_user,
      @path,
      @project_wiki,
      @ref
    )

    preload_max_access_for_authors(@notes, @project)
  end

  def define_widget_vars
    @pipeline = @merge_request.pipeline
    @pipelines = [@pipeline].compact
  end

  def define_commit_vars
    @commit = @merge_request.diff_head_commit
    @base_commit = @merge_request.diff_base_commit || @merge_request.likely_diff_base_commit
  end

  def define_diff_comment_vars
    @comments_target = {
      noteable_type: 'MergeRequest',
      noteable_id: @merge_request.id
    }

    @use_legacy_diff_notes = !@merge_request.support_new_diff_notes?
    @grouped_diff_discussions = @merge_request.notes.inc_author_project_award_emoji.grouped_diff_discussions

    Banzai::NoteRenderer.render(
      @grouped_diff_discussions.values.flat_map(&:notes),
      @project,
      current_user,
      @path,
      @project_wiki,
      @ref
    )
  end

  def invalid_mr
    # Render special view for MR with removed source or target branch
    render 'invalid'
  end

  def set_suggested_approvers
    if @merge_request.requires_approve?
      @suggested_approvers = Gitlab::AuthorityAnalyzer.new(
        @merge_request
      ).calculate(@merge_request.approvals_required)
    end
  end

  def merge_request_params
    params.require(:merge_request).permit(
      :title, :assignee_id, :source_project_id, :source_branch,
      :target_project_id, :target_branch, :milestone_id, :approver_ids,
      :state_event, :description, :task_num, :force_remove_source_branch,
      :approvals_before_merge, label_ids: []
    )
  end

  def clamp_approvals_before_merge(mr_params)
    target_project = @project.forked_from_project if @project.id.to_s != mr_params[:target_project_id]
    target_project ||= @project

    if mr_params[:approvals_before_merge].to_i <= target_project.approvals_before_merge
      mr_params.delete(:approvals_before_merge)
    end

    mr_params
  end

  def merge_params
    params.permit(:should_remove_source_branch, :commit_message)
  end

  # Make sure merge requests created before 8.0
  # have head file in refs/merge-requests/
  def ensure_ref_fetched
    @merge_request.ensure_ref_fetched
  end

  def merge_when_build_succeeds_active?
    params[:merge_when_build_succeeds].present? &&
      @merge_request.pipeline && @merge_request.pipeline.active?
  end

  def build_merge_request
    params[:merge_request] ||= ActionController::Parameters.new(source_project: @project)
    @merge_request = MergeRequests::BuildService.new(project, current_user, merge_request_params).execute
  end
end

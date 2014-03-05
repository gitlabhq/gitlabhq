require 'gitlab/satellite/satellite'

class Projects::MergeRequestsController < Projects::ApplicationController
  before_filter :module_enabled
  before_filter :merge_request, only: [:edit, :update, :show, :diffs, :automerge, :automerge_check, :ci_status]
  before_filter :closes_issues, only: [:edit, :update, :show, :diffs]
  before_filter :validates_merge_request, only: [:show, :diffs]
  before_filter :define_show_vars, only: [:show, :diffs]

  # Allow read any merge_request
  before_filter :authorize_read_merge_request!

  # Allow write(create) merge_request
  before_filter :authorize_write_merge_request!, only: [:new, :create]

  # Allow modify merge_request
  before_filter :authorize_modify_merge_request!, only: [:close, :edit, :update, :sort]

  def index
    params[:sort] ||= 'newest'
    params[:scope] = 'all' if params[:scope].blank?
    params[:state] = 'opened' if params[:state].blank?

    @merge_requests = FilteringService.new.execute(MergeRequest, current_user, params.merge(project_id: @project.id))
    @merge_requests = @merge_requests.page(params[:page]).per(20)

    @sort = params[:sort].humanize
    assignee_id, milestone_id = params[:assignee_id], params[:milestone_id]
    @assignee = @project.team.find(assignee_id) if assignee_id.present? && !assignee_id.to_i.zero?
    @milestone = @project.milestones.find(milestone_id) if milestone_id.present? && !milestone_id.to_i.zero?
    @assignees = User.where(id: @project.merge_requests.pluck(:assignee_id))
  end

  def show
    respond_to do |format|
      format.html
      format.diff { render text: @merge_request.to_diff(current_user) }
      format.patch { render text: @merge_request.to_patch(current_user) }
    end
  end

  def diffs
    @commit = @merge_request.last_commit

    @comments_allowed = @reply_allowed = true
    @comments_target = {noteable_type: 'MergeRequest',
                        noteable_id: @merge_request.id}
    @line_notes = @merge_request.notes.where("line_code is not null")

    diff_line_count = Commit::diff_line_count(@merge_request.diffs)
    @suppress_diff = Commit::diff_suppress?(@merge_request.diffs, diff_line_count) && !params[:force_show_diff]
    @force_suppress_diff = Commit::diff_force_suppress?(@merge_request.diffs, diff_line_count)

    respond_to do |format|
      format.html
      format.json { render json: { html: view_to_html_string("projects/merge_requests/show/_diffs") } }
    end
  end

  def new
    @merge_request = MergeRequest.new(params[:merge_request])
    @merge_request.source_project = @project unless @merge_request.source_project
    @merge_request.target_project = @project unless @merge_request.target_project
    @source_project = @merge_request.source_project
    @merge_request
  end

  def edit
    @source_project = @merge_request.source_project
    @target_project = @merge_request.target_project
    @target_branches = @merge_request.target_project.repository.branch_names
  end

  def create
    @merge_request = MergeRequest.new(params[:merge_request])
    @merge_request.author = current_user
    @target_branches ||= []
    if @merge_request.save
      redirect_to [@merge_request.target_project, @merge_request], notice: 'Merge request was successfully created.'
    else
      @source_project = @merge_request.source_project
      @target_project = @merge_request.target_project
      render action: "new"
    end
  end

  def update
    # If we close MergeRequest we want to ignore validation
    # so we can close broken one (Ex. fork project removed)
    if params[:merge_request] == {"state_event"=>"close"}
      @merge_request.allow_broken = true

      if @merge_request.close
        opts = { notice: 'Merge request was successfully closed.' }
      else
        opts = { alert: 'Failed to close merge request.' }
      end

      redirect_to [@merge_request.target_project, @merge_request], opts
      return
    end

    # We dont allow change of source/target projects
    # after merge request was created
    params[:merge_request].delete(:source_project_id)
    params[:merge_request].delete(:target_project_id)

    if @merge_request.update_attributes(params[:merge_request].merge(author_id_of_changes: current_user.id))
      @merge_request.reset_events_cache

      respond_to do |format|
        format.js
        format.html do
          redirect_to [@merge_request.target_project, @merge_request], notice: 'Merge request was successfully updated.'
        end
      end
    else
      render "edit"
    end
  end

  def automerge_check
    if @merge_request.unchecked?
      @merge_request.check_if_can_be_merged
    end
    render json: {merge_status: @merge_request.merge_status_name}
  rescue Gitlab::SatelliteNotExistError
    render json: {merge_status: :no_satellite}
  end

  def automerge
    return access_denied! unless allowed_to_merge?

    if @merge_request.open? && @merge_request.can_be_merged?
      @merge_request.should_remove_source_branch = params[:should_remove_source_branch]
      @merge_request.automerge!(current_user, params[:merge_commit_message])
      @status = true
    else
      @status = false
    end
  end

  def branch_from
    #This is always source
    @source_project = @merge_request.nil? ? @project : @merge_request.source_project
    @commit = @repository.commit(params[:ref]) if params[:ref].present?
  end

  def branch_to
    @target_project = selected_target_project
    @commit = @target_project.repository.commit(params[:ref]) if params[:ref].present?
  end

  def update_branches
    @target_project = selected_target_project
    @target_branches = @target_project.repository.branch_names
    @target_branches

    respond_to do |format|
      format.js
    end
  end

  def ci_status
    status = project.gitlab_ci_service.commit_status(merge_request.last_commit.sha)
    response = {status: status}

    render json: response
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

  def closes_issues
    @closes_issues ||= @merge_request.closes_issues
  end

  def authorize_modify_merge_request!
    return render_404 unless can?(current_user, :modify_merge_request, @merge_request)
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
    # Build a note object for comment form
    @note = @project.notes.new(noteable: @merge_request)
    @notes = @merge_request.mr_and_commit_notes.inc_author.fresh
    @discussions = Note.discussions_from_notes(@notes)
    @noteable = @merge_request

    # Get commits from repository
    # or from cache if already merged
    @commits = @merge_request.commits

    @merge_request_diff = @merge_request.merge_request_diff
    @allowed_to_merge = allowed_to_merge?
    @show_merge_controls = @merge_request.open? && @commits.any? && @allowed_to_merge
  end

  def allowed_to_merge?
    action = if project.protected_branch?(@merge_request.target_branch)
               :push_code_to_protected_branches
             else
               :push_code
             end

    can?(current_user, action, @project)
  end

  def invalid_mr
    # Render special view for MR with removed source or target branch
    render 'invalid'
  end
end

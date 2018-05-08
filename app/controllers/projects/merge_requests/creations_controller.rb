class Projects::MergeRequests::CreationsController < Projects::MergeRequests::ApplicationController
  include DiffForPath
  include DiffHelper
  include RendersCommits

  skip_before_action :merge_request
  before_action :whitelist_query_limiting, only: [:create]
  before_action :authorize_create_merge_request_from!
  before_action :apply_diff_view_cookie!, only: [:diffs, :diff_for_path]
  before_action :build_merge_request, except: [:create]

  def new
    # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/40934
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      define_new_vars
    end
  end

  def create
    @target_branches ||= []
    @merge_request = ::MergeRequests::CreateService.new(project, current_user, merge_request_params).execute

    if @merge_request.valid?
      redirect_to(merge_request_path(@merge_request))
    else
      @source_project = @merge_request.source_project
      @target_project = @merge_request.target_project

      define_new_vars
      render action: "new"
    end
  end

  def pipelines
    @pipelines = @merge_request.all_pipelines

    Gitlab::PollingInterval.set_header(response, interval: 10_000)

    render json: {
      pipelines: PipelineSerializer
      .new(project: @project, current_user: @current_user)
      .represent(@pipelines)
    }
  end

  def diffs
    @diffs = @merge_request.diffs(diff_options) if @merge_request.can_be_created

    @diff_notes_disabled = true

    @environment = @merge_request.environments_for(current_user).last

    render json: { html: view_to_html_string('projects/merge_requests/creations/_diffs', diffs: @diffs, environment: @environment) }
  end

  def diff_for_path
    @diffs = @merge_request.diffs(diff_options)
    @diff_notes_disabled = true

    render_diff_for_path(@diffs)
  end

  def branch_from
    # This is always source
    @source_project = @merge_request.nil? ? @project : @merge_request.source_project

    if params[:ref].present?
      @ref = params[:ref]
      @commit = @repository.commit(Gitlab::Git::BRANCH_REF_PREFIX + @ref)
    end

    render layout: false
  end

  def branch_to
    @target_project = selected_target_project

    if @target_project && params[:ref].present?
      @ref = params[:ref]
      @commit = @target_project.commit(Gitlab::Git::BRANCH_REF_PREFIX + @ref)
    end

    render layout: false
  end

  def update_branches
    @target_project = selected_target_project
    @target_branches = @target_project ? @target_project.repository.branch_names : []

    render layout: false
  end

  private

  def build_merge_request
    params[:merge_request] ||= ActionController::Parameters.new(source_project: @project)
    @merge_request = ::MergeRequests::BuildService.new(project, current_user, merge_request_params.merge(diff_options: diff_options)).execute
  end

  def define_new_vars
    @noteable = @merge_request

    @target_branches = if @merge_request.target_project
                         @merge_request.target_project.repository.branch_names
                       else
                         []
                       end

    @target_project = @merge_request.target_project
    @source_project = @merge_request.source_project
    @commits = prepare_commits_for_rendering(@merge_request.commits)
    @commit = @merge_request.diff_head_commit

    @labels = LabelsFinder.new(current_user, project_id: @project.id).execute

    set_pipeline_variables
  end

  def selected_target_project
    if @project.id.to_s == params[:target_project_id] || !@project.forked?
      @project
    elsif params[:target_project_id].present?
      MergeRequestTargetProjectFinder.new(current_user: current_user, source_project: @project)
        .find_by(id: params[:target_project_id])
    else
      @project.forked_from_project
    end
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42384')
  end
end

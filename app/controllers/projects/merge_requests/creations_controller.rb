# frozen_string_literal: true

class Projects::MergeRequests::CreationsController < Projects::MergeRequests::ApplicationController
  include DiffForPath
  include DiffHelper
  include RendersCommits

  skip_before_action :merge_request
  before_action :authorize_create_merge_request_from!
  before_action :apply_diff_view_cookie!, only: [:diffs, :diff_for_path]
  before_action :build_merge_request, except: [:create]

  before_action do
    push_frontend_feature_flag(:mr_collapsed_approval_rules, @project)
  end

  def new
    define_new_vars
  end

  def create
    @merge_request = ::MergeRequests::CreateService.new(project: project, current_user: current_user, params: merge_request_params).execute

    if @merge_request.valid?
      incr_count_webide_merge_request

      redirect_to(merge_request_path(@merge_request))
    else
      @source_project = @merge_request.source_project
      @target_project = @merge_request.target_project

      define_new_vars
      render action: "new"
    end
  end

  def pipelines
    @pipelines = Ci::PipelinesForMergeRequestFinder.new(@merge_request, current_user).execute

    Gitlab::PollingInterval.set_header(response, interval: 10_000)

    render json: {
      pipelines: PipelineSerializer
      .new(project: @project, current_user: current_user)
      .represent(@pipelines)
    }
  end

  def diffs
    @diffs = @merge_request.diffs(diff_options) if @merge_request.can_be_created

    @diff_notes_disabled = true

    @environment = @merge_request.environments_for(current_user, latest: true).last

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

  private

  def build_merge_request
    params[:merge_request] ||= ActionController::Parameters.new(source_project: @project)

    # Gitaly N+1 issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/58096
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      @merge_request = ::MergeRequests::BuildService.new(project: project, current_user: current_user, params: merge_request_params.merge(diff_options: diff_options)).execute
    end
  end

  def define_new_vars
    @noteable = @merge_request
    @target_project = @merge_request.target_project
    @source_project = @merge_request.source_project

    @commits =
      set_commits_for_rendering(
        @merge_request.recent_commits.with_latest_pipeline(@merge_request.source_branch),
          commits_count: @merge_request.commits_count
      )

    @commit = @merge_request.diff_head_commit

    # FIXME: We have to assign a presenter to another instance variable
    # due to class_name checks being made with issuable classes
    @mr_presenter = @merge_request.present(current_user: current_user)

    @labels = LabelsFinder.new(current_user, project_id: @project.id).execute

    set_pipeline_variables
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def selected_target_project
    return @project unless @project.forked?

    if params[:target_project_id].present?
      return @project if @project.id.to_s == params[:target_project_id]

      MergeRequestTargetProjectFinder.new(current_user: current_user, source_project: @project)
        .find_by(id: params[:target_project_id])
    else
      @project.default_merge_request_target
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def incr_count_webide_merge_request
    return if params[:nav_source] != 'webide'

    Gitlab::UsageDataCounters::WebIdeCounter.increment_merge_requests_count
  end
end

Projects::MergeRequests::CreationsController.prepend_mod

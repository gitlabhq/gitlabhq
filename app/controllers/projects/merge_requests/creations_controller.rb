# frozen_string_literal: true

class Projects::MergeRequests::CreationsController < Projects::MergeRequests::ApplicationController
  include DiffForPath
  include DiffHelper
  include RendersCommits
  include ProductAnalyticsTracking

  skip_before_action :merge_request
  before_action :authorize_create_merge_request_from!
  before_action :apply_diff_view_cookie!, only: [:diffs, :diff_for_path]
  before_action :build_merge_request, except: [:create]

  before_action only: [:new] do
    if can?(current_user, :fill_in_merge_request_template, project)
      push_frontend_feature_flag(:fill_in_mr_template, project)
    end
  end

  urgency :low, [
    :new,
    :create,
    :pipelines,
    :diffs,
    :branch_from,
    :branch_to
  ]

  track_internal_event :new, name: 'create_mr_web_ide', conditions: -> { webide_source? }

  track_internal_event :new,
    name: 'visit_after_push_link_or_create_mr_banner',
    conditions: -> { after_push_link? }

  def new
    define_new_vars
  end

  def create
    @merge_request = ::MergeRequests::CreateService
      .new(project: project, current_user: current_user, params: merge_request_params)
      .execute

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

    render json: { html: view_to_html_string('projects/merge_requests/creations/_diffs', diffs: @diffs) }
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

    if @target_project &&
        params[:ref].present? &&
        Ability.allowed?(current_user, :create_merge_request_in, @target_project)

      @ref = params[:ref]
      @commit = @target_project.commit(Gitlab::Git::BRANCH_REF_PREFIX + @ref)
    end

    render layout: false
  end

  def target_projects
    render json: ProjectSerializer.new.represent(get_target_projects)
  end

  private

  def get_target_projects
    MergeRequestTargetProjectFinder
      .new(current_user: current_user, source_project: @project, project_feature: :repository)
      .execute(include_routes: false, search: params[:search]).limit(20)
  end

  def build_merge_request
    params[:merge_request] ||= ActionController::Parameters.new(source_project: @project)
    new_params = merge_request_params.merge(diff_options: diff_options)

    # Gitaly N+1 issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/58096
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      @merge_request = ::MergeRequests::BuildService
        .new(project: project, current_user: current_user, params: new_params)
        .execute
    end
  end

  def define_new_vars
    @noteable = @merge_request
    @target_project = @merge_request.target_project
    @source_project = @merge_request.source_project

    @commits = set_commits_for_rendering(
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

  def webide_source?
    params[:nav_source] == 'webide'
  end

  def after_push_link?
    # Link in the console after you push changes:
    # .../-/merge_requests/new?merge_request%5Bsource_branch%5D=branch-name
    request.query_parameters.keys == ['merge_request'] &&
      request.query_parameters['merge_request'].keys == ['source_branch']
  end

  def incr_count_webide_merge_request
    webide_source? && Gitlab::UsageDataCounters::WebIdeCounter.increment_merge_requests_count
  end

  def tracking_project_source
    @project
  end

  def tracking_namespace_source
    @project.namespace
  end
end

Projects::MergeRequests::CreationsController.prepend_mod

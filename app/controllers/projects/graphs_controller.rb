# frozen_string_literal: true

class Projects::GraphsController < Projects::ApplicationController
  include ExtractsPath
  include ProductAnalyticsTracking

  # Authorize
  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_read_repository_graphs!

  track_event :charts,
    name: 'p_analytics_repo',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  feature_category :source_code_management, [:show, :commits, :languages, :charts]
  urgency :low, [:show]

  feature_category :continuous_integration, [:ci]
  urgency :low, [:ci]

  MAX_COMMITS = 6000

  def show
    @ref_type = ref_type

    respond_to do |format|
      format.html
      format.json do
        commits = @project.repository.commits(ref, limit: MAX_COMMITS, skip_merges: true)
        log = commits.map do |commit|
          {
            author_name: commit.author_name,
            author_email: commit.author_email,
            date: commit.committed_date.to_date.iso8601
          }
        end

        render json: Gitlab::Json.dump(log)
      end
    end
  end

  def commits
    redirect_to action: 'charts'
  end

  def languages
    redirect_to action: 'charts'
  end

  def charts
    get_commits
    get_languages
    get_daily_coverage_options
  end

  def ci
    redirect_to charts_project_pipelines_path(@project)
  end

  private

  def ref
    @fully_qualified_ref || @ref
  end

  def get_commits
    @commits_limit = 2000
    @commits = @project.repository.commits(ref, limit: @commits_limit, skip_merges: true)
    @commits_graph = Gitlab::Graphs::Commits.new(@commits)
    @commits_per_week_days = @commits_graph.commits_per_week_days
    @commits_per_time = @commits_graph.commits_per_time
    @commits_per_month = @commits_graph.commits_per_month
  end

  def get_languages
    @languages =
      ::Projects::RepositoryLanguagesService.new(@project, current_user).execute.map do |lang|
        { value: lang.share, label: lang.name, color: lang.color, highlight: lang.color }
      end
  end

  def get_daily_coverage_options
    return unless can?(current_user, :read_build_report_results, project)

    date_today = Date.current
    report_window = ::Ci::DailyBuildGroupReportResultsFinder::REPORT_WINDOW

    @daily_coverage_options = {
      base_params: {
        start_date: date_today - report_window,
        end_date: date_today,
        ref_path: @project.repository.expand_ref(ref),
        param_type: 'coverage'
      },
      download_path: namespace_project_ci_daily_build_group_report_results_path(
        namespace_id: @project.namespace,
        project_id: @project,
        format: :csv
      ),
      graph_api_path: namespace_project_ci_daily_build_group_report_results_path(
        namespace_id: @project.namespace,
        project_id: @project,
        format: :json
      )
    }
  end

  def tracking_namespace_source
    project.namespace
  end

  def tracking_project_source
    project
  end
end

Projects::GraphsController.prepend_mod

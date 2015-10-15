class Projects::GraphsController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!
  before_action :ci_enabled, only: :ci

  def show
    respond_to do |format|
      format.html
      format.json do
        fetch_graph
      end
    end
  end

  def commits
    @commits = @project.repository.commits(@ref, nil, 2000, 0, true)
    @commits_graph = Gitlab::Graphs::Commits.new(@commits)
    @commits_per_week_days = @commits_graph.commits_per_week_days
    @commits_per_time = @commits_graph.commits_per_time
    @commits_per_month = @commits_graph.commits_per_month
  end

  def ci
    ci_project = @project.gitlab_ci_project

    @charts = {}
    @charts[:week] = Ci::Charts::WeekChart.new(ci_project)
    @charts[:month] = Ci::Charts::MonthChart.new(ci_project)
    @charts[:year] = Ci::Charts::YearChart.new(ci_project)
    @charts[:build_times] = Ci::Charts::BuildTime.new(ci_project)
  end

  private

  def fetch_graph
    @commits = @project.repository.commits(@ref, nil, 6000, 0, true)
    @log = []

    @commits.each do |commit|
      @log << {
        author_name: commit.author_name,
        author_email: commit.author_email,
        date: commit.committed_date.strftime("%Y-%m-%d")
      }
    end

    render json: @log.to_json
  end
end

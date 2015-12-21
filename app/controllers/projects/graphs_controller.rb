class Projects::GraphsController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!
  before_action :builds_enabled, only: :ci

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
    @charts = {}
    @charts[:week] = Ci::Charts::WeekChart.new(project)
    @charts[:month] = Ci::Charts::MonthChart.new(project)
    @charts[:year] = Ci::Charts::YearChart.new(project)
    @charts[:build_times] = Ci::Charts::BuildTime.new(project)
  end

  def languages
    @languages = Linguist::Repository.new(@repository.rugged, @repository.rugged.head.target_id).languages
    total = @languages.map(&:last).sum

    @languages = @languages.map do |language|
      name, share = language
      color = Digest::SHA256.hexdigest(name)[0...6]
      {
        value: (share.to_f * 100 / total).round(2),
        label: name,
        color: "##{color}",
        highlight: "##{color}"
      }
    end

    @languages.sort! do |x, y|
      y[:value] <=> x[:value]
    end
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

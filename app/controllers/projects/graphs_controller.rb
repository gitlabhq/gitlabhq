class Projects::GraphsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_download_code!
  before_filter :require_non_empty_project

  def show
    respond_to do |format|
      format.html
      format.json do
        fetch_graph
      end
    end
  end

  def commits
    @commits = @project.repository.commits(nil, nil, 2000, 0, true)
    @commits_graph = Gitlab::Graphs::Commits.new(@commits)
    @commits_per_week_days = @commits_graph.commits_per_week_days
    @commits_per_time = @commits_graph.commits_per_time
    @commits_per_month = @commits_graph.commits_per_month
  end

  private

  def fetch_graph
    @commits = @project.repository.commits(nil, nil, 6000, 0, true)
    @log = []

    @commits.each do |commit|
      @log << {
        author_name: commit.author_name.force_encoding('UTF-8'),
        author_email: commit.author_email.force_encoding('UTF-8'),
        date: commit.committed_date.strftime("%Y-%m-%d")
      }
    end

    render json: @log.to_json
  end
end

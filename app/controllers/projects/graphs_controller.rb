class Projects::GraphsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
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
    @start_date = @commits.last.committed_date.to_date
    @end_date = @commits.first.committed_date.to_date
    @duration = (@end_date - @start_date).to_i
    @authors = @commits.map(&:author_email).uniq.size
    @commit_per_day = (@commits.size.to_f / @duration).round(1)

    @commits_per_week_days = {}
    Date::DAYNAMES.each { |day| @commits_per_week_days[day] = 0 }

    @commits_per_time = {}
    (0..23).to_a.each { |hour| @commits_per_time[hour] = 0 }

    @commits_per_month = {}
    (1..31).to_a.each { |day| @commits_per_month[day] = 0 }

    @commits.each do |commit|
      hour = commit.committed_date.strftime('%k').to_i
      day_of_month = commit.committed_date.strftime('%e').to_i
      weekday = commit.committed_date.strftime('%A')

      @commits_per_week_days[weekday] ||= 0
      @commits_per_week_days[weekday] += 1
      @commits_per_time[hour] ||= 0
      @commits_per_time[hour] += 1
      @commits_per_month[day_of_month] ||= 0
      @commits_per_month[day_of_month] += 1
    end
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

module UsersHelper
  def create_timestamp(user_projects)
    timestamps = {}
    user_projects.each do |raw_repository|
      if raw_repository.exists?
        commits_log = commits_log_by_commit_date(raw_repository.graph_log)
        commits_log.each do |k, v|
          hash = { "#{k}" => v.count }
          if timestamps.has_key?("#{k}")
            timestamps.merge!(hash) { |k, v, v2| v = v.to_i + v2 }
          else
            timestamps.merge!(hash)
          end
        end
      end
    end
    timestamps
  end

  def create_timestamps_by_project(user_projects)
    projects = {}
    project_commit = {}
    timestamps_copy = {}

    user_projects.each do |raw_repository|
      if raw_repository.exists?
        commits_log = commits_log_by_commit_date(raw_repository.graph_log)
        commits_log.each do |k, v|
          if timestamps_copy.has_key?("#{k}")
            timestamps_copy["#{k}"].
              merge!(raw_repository.path_with_namespace => v.count)
          else
            hash = { "#{k}" => { raw_repository.path_with_namespace => v.count }
                                }
            timestamps_copy.merge!(hash)
          end
        end
        project_commit = project_commits(timestamps_copy,
                                         raw_repository.path_with_namespace)
        projects.merge!(timestamps_copy)
      end
    end
    projects
  end

  def project_commits(timestamps, repository_name)
    timestamps.each do |date|
      hash = { "#{timestamps}" => repository_name }
    end
  end

  def create_time_copy(user_projects)
    timestamps = create_timestamp(user_projects)
    time_copy = if timestamps.empty?
                  DateTime.now.to_date
                else
                  Time.at(timestamps.first.first.to_i).to_date
                end
    time_copy
  end

  def timestart_year
    create_time_copy(@user_projects).year - 1
  end

  def timestart_month
    create_time_copy(@user_projects).month
  end

  def last_commit_date
    create_time_copy(@user_projects).to_formatted_s(:long).to_s
  end

  def commits_log_by_commit_date(graph_log)
    graph_log.select { |u_email| u_email[:author_email] == @user.email }.
      map { |graph_log| Date.parse(graph_log[:date]).to_time.to_i }.
      group_by { |commit_date| commit_date }
  end

  def commit_activity_match(user_activities)
    user_activities.select { |x| Time.at(x.to_i) == Time.parse(params[:date]) }
  end
end

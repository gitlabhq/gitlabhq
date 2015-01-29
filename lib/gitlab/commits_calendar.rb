module Gitlab
  class CommitsCalendar
    def self.create_timestamp(repositories, user, show_activity)
      timestamps = {}
      repositories.each do |raw_repository|
        if raw_repository.exists?
          commits_log = raw_repository.commits_log_of_user_by_date(user)

          populated_timestamps =
            if show_activity
              populate_timestamps_by_project(
                commits_log,
                timestamps,
                raw_repository
              )
            else
              populate_timestamps(commits_log, timestamps)
            end
          timestamps.merge!(populated_timestamps)
        end
      end
      timestamps
    end

    def self.populate_timestamps(commits_log, timestamps)
      commits_log.each do |timestamp_date, commits_count|
        hash = { "#{timestamp_date}" => commits_count }
        if timestamps.has_key?("#{timestamp_date}")
          timestamps.merge!(hash) do |timestamp_date, commits_count,
            new_commits_count| commits_count = commits_count.to_i +
            new_commits_count
          end
        else
          timestamps.merge!(hash)
        end
      end
      timestamps
    end

    def self.populate_timestamps_by_project(commits_log, timestamps,
                                            project)
      commits_log.each do |timestamp_date, commits_count|
        if timestamps.has_key?("#{timestamp_date}")
          timestamps["#{timestamp_date}"].
            merge!(project.path_with_namespace => commits_count)
        else
          hash = { "#{timestamp_date}" => { project.path_with_namespace =>
                                            commits_count } }
          timestamps.merge!(hash)
        end
      end
      timestamps
    end

    def self.latest_commit_date(timestamps)
      if timestamps.nil? || timestamps.empty?
        DateTime.now.to_date
      else
        Time.at(timestamps.keys.first.to_i).to_date
      end
    end

    def self.last_commit_date(timestamps)
      latest_commit_date(timestamps).to_formatted_s(:long).to_s
    end

    def self.commit_activity_match(user_activities, date)
      user_activities.select { |x| Time.at(x.to_i) == Time.parse(date) }
    end
  end
end

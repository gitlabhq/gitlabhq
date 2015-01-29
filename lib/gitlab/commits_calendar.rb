module Gitlab
  class CommitsCalendar
    attr_reader :timestamps

    def initialize(repositories, user)
      @timestamps = {}
      date_timestamps = []

      repositories.select(&:exists?).reject(&:empty?).each do |raw_repository|
        commits_log = raw_repository.commits_per_day_for_user(user)
        date_timestamps << commits_log
      end

      date_timestamps = date_timestamps.inject do |collection, date|
        collection.merge(date) { |k, old_v, new_v| old_v + new_v }
      end

      date_timestamps ||= []
      date_timestamps.each do |date, commits|
        timestamp = Date.parse(date).to_time.to_i.to_s
        @timestamps[timestamp] = commits
      end
    end
  end
end

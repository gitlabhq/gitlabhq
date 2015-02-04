module Gitlab
  class CommitsCalendar
    attr_reader :timestamps

    def initialize(projects, user)
      @timestamps = {}
      date_timestamps = []

      projects.reject(&:forked?).each do |project|
        date_timestamps << ProjectContributions.new(project, user).commits_log
      end

      # Sumarrize commits from all projects per days
      date_timestamps = date_timestamps.inject do |collection, date|
        collection.merge(date) { |k, old_v, new_v| old_v + new_v }
      end

      date_timestamps ||= []
      date_timestamps.each do |date, commits|
        timestamp = Date.parse(date).to_time.to_i.to_s rescue nil
        @timestamps[timestamp] = commits if timestamp
      end
    end

    def starting_year
      (Time.now - 1.year).strftime("%Y")
    end

    def starting_month
      Date.today.strftime("%m").to_i
    end
  end
end

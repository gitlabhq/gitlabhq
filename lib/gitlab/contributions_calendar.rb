module Gitlab
  class ContributionsCalendar
    attr_reader :timestamps, :projects, :user

    def initialize(projects, user)
      @projects = projects
      @user = user
    end

    def timestamps
      return @timestamps if @timestamps.present?

      @timestamps = {}
      date_from = 1.year.ago

      events = Event.reorder(nil).contributions.where(author_id: user.id).
        where("created_at > ?", date_from).where(project_id: projects).
        group('date(created_at)').
        select('date(created_at) as date, count(id) as total_amount').
        map(&:attributes)

      dates = (1.year.ago.to_date..(Date.today + 1.day)).to_a

      dates.each do |date|
        date_id = date.to_time.to_i.to_s
        @timestamps[date_id] = 0
        day_events = events.find { |day_events| day_events["date"] == date }

        if day_events
          @timestamps[date_id] = day_events["total_amount"]
        end
      end

      @timestamps
    end

    def events_by_date(date)
      events = Event.contributions.where(author_id: user.id).
        where("created_at > ? AND created_at < ?", date.beginning_of_day, date.end_of_day).
        where(project_id: projects)

      events.select do |event|
        event.push? || event.issue? || event.merge_request?
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

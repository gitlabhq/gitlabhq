module Gitlab
  class ContributionsCalendar
    attr_reader :activity_dates, :projects, :user

    def initialize(projects, user)
      @projects = projects
      @user = user
    end

    def activity_dates
      return @activity_dates if @activity_dates.present?

      @activity_dates = {}
      date_from = 1.year.ago

      events = Event.reorder(nil).contributions.where(author_id: user.id).
        where("created_at > ?", date_from).where(project_id: projects).
        group('date(created_at)').
        select('date(created_at) as date, count(id) as total_amount').
        map(&:attributes)

      activity_dates = (1.year.ago.to_date..Date.today).to_a

      activity_dates.each do |date|
        day_events = events.find { |day_events| day_events["date"] == date }

        if day_events
          @activity_dates[date] = day_events["total_amount"]
        end
      end

      @activity_dates
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
      1.year.ago.year
    end

    def starting_month
      Date.today.month
    end
  end
end

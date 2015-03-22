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
      date_to = Date.today

      events = Event.where(author_id: user.id).where(action: event_type).
        where("created_at > ?", date_from).where(project_id: projects)

      grouped_events = events.to_a.group_by { |event| event.created_at.to_date.to_s }
      dates = (1.year.ago.to_date..(Date.today + 1.day)).to_a

      dates.each do |date|
        date_id = date.to_time.to_i.to_s
        @timestamps[date_id] = 0

        if grouped_events.has_key?(date.to_s)
          grouped_events[date.to_s].each do |event|
            if event.created_at.to_date == date
              if event.issue? || event.merge_request?
                @timestamps[date_id] += 1
              elsif event.push?
                @timestamps[date_id] += event.commits_count
              end
            end
          end
        end
      end

      @timestamps
    end

    def events_by_date(date)
      events = Event.where(author_id: user.id).where(action: event_type).
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

    def event_type
      [Event::PUSHED, Event::CREATED, Event::CLOSED, Event::MERGED]
    end
  end
end

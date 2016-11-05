module Gitlab
  class ContributionsCalendar
    attr_reader :contributor
    attr_reader :current_user
    attr_reader :projects

    def initialize(contributor, current_user = nil)
      @contributor = contributor
      @current_user = current_user
      @projects = ContributedProjectsFinder.new(contributor).execute(current_user)
    end

    def activity_dates
      return @activity_dates if @activity_dates.present?

      contributions_data = UserContributionCalendar.new(contributor).calculate
      @activity_events = contributions_data
    end

    def events_by_date(date)
      events = Event.contributions.where(author_id: contributor.id)
        .where(created_at: date.beginning_of_day..date.end_of_day)
        .where(project_id: projects)

      # Use visible_to_user? instead of the complicated logic in activity_dates
      # because we're only viewing the events for a single day.
      events.select { |event| event.visible_to_user?(current_user) }
    end

    def starting_year
      1.year.ago.year
    end

    def starting_month
      Date.current.month
    end
  end
end

# frozen_string_literal: true

module Gitlab
  class ContributionsCalendar
    include TimeZoneHelper

    attr_reader :contributor
    attr_reader :current_user
    attr_reader :projects

    def initialize(contributor, current_user = nil)
      @contributor = contributor
      @contributor_time_instance = local_timezone_instance(contributor.timezone).now
      @current_user = current_user
      @projects = ContributedProjectsFinder.new(contributor)
        .execute(current_user, ignore_visibility: @contributor.include_private_contributions?)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def activity_dates
      return {} if @projects.empty?
      return @activity_dates if @activity_dates.present?

      start_time = @contributor_time_instance.years_ago(1).beginning_of_day
      end_time = @contributor_time_instance.end_of_day

      date_interval = "INTERVAL '#{@contributor_time_instance.utc_offset} seconds'"

      # Can't use Event.contributions here because we need to check 3 different
      # project_features for the (currently) 3 different contribution types
      repo_events = events_created_between(start_time, end_time, :repository)
        .where(action: :pushed)
      issue_events = events_created_between(start_time, end_time, :issues)
        .where(action: [:created, :closed], target_type: %w[Issue WorkItem])
      mr_events = events_created_between(start_time, end_time, :merge_requests)
        .where(action: [:merged, :created, :closed], target_type: "MergeRequest")
      note_events = events_created_between(start_time, end_time, :merge_requests)
        .where(action: :commented)

      events = Event
        .select("date(created_at + #{date_interval}) AS date", 'COUNT(*) AS num_events')
        .from_union([repo_events, issue_events, mr_events, note_events], remove_duplicates: false)
        .group(:date)
        .map(&:attributes)

      @activity_dates = events.each_with_object(Hash.new { |h, k| h[k] = 0 }) do |event, activities|
        activities[event["date"]] += event["num_events"]
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def events_by_date(date)
      return Event.none unless can_read_cross_project?

      date_in_time_zone = date.in_time_zone(@contributor_time_instance.time_zone)

      Event.contributions.where(author_id: contributor.id)
        .where(created_at: date_in_time_zone.beginning_of_day..date_in_time_zone.end_of_day)
        .where(project_id: projects)
        .with_associations
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def starting_year
      @contributor_time_instance.years_ago(1).year
    end

    def starting_month
      @contributor_time_instance.month
    end

    private

    def can_read_cross_project?
      Ability.allowed?(current_user, :read_cross_project)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def events_created_between(start_time, end_time, feature)
      # re-running the contributed projects query in each union is expensive, so
      # use IN(project_ids...) instead. It's the intersection of two users so
      # the list will be (relatively) short
      @contributed_project_ids ||= projects.distinct.pluck(:id)

      # no need to check feature access of current user, if the contributor opted-in
      # to show all private events anyway - otherwise they would get filtered out again
      authed_projects = if @contributor.include_private_contributions?
                          @contributed_project_ids
                        else
                          ProjectFeature
                            .with_feature_available_for_user(feature, current_user)
                            .where(project_id: @contributed_project_ids)
                            .reorder(nil)
                            .select(:project_id)
                        end

      Event.reorder(nil)
        .select(:created_at)
        .where(
          author_id: contributor.id,
          created_at: start_time..end_time,
          events: { project_id: authed_projects }
        )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

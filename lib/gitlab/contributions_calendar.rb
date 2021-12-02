# frozen_string_literal: true

module Gitlab
  class ContributionsCalendar
    include TimeZoneHelper

    attr_reader :contributor
    attr_reader :current_user
    attr_reader :projects

    def initialize(contributor, current_user = nil)
      @contributor = contributor
      @contributor_time_instance = local_time_instance(contributor.timezone)
      @current_user = current_user
      @projects = if @contributor.include_private_contributions?
                    ContributedProjectsFinder.new(@contributor).execute(@contributor)
                  else
                    ContributedProjectsFinder.new(contributor).execute(current_user)
                  end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def activity_dates
      return @activity_dates if @activity_dates.present?

      date_interval = "INTERVAL '#{@contributor_time_instance.now.utc_offset} seconds'"

      # Can't use Event.contributions here because we need to check 3 different
      # project_features for the (currently) 3 different contribution types
      date_from = @contributor_time_instance.now.years_ago(1)
      repo_events = event_created_at(date_from, :repository)
        .where(action: :pushed, target_type: nil)
      issue_events = event_created_at(date_from, :issues)
        .where(action: [:created, :closed], target_type: "Issue")
      mr_events = event_created_at(date_from, :merge_requests)
        .where(action: [:merged, :created, :closed], target_type: "MergeRequest")
      note_events = event_created_at(date_from, :merge_requests)
        .where(action: :commented, target_type: "Note")

      events = Event
        .select("date(created_at + #{date_interval}) AS date", 'COUNT(*) AS num_events')
        .from_union([repo_events, issue_events, mr_events, note_events], remove_duplicates: false)
        .group(:date)
        .map(&:attributes)

      @activity_dates = events.each_with_object(Hash.new {|h, k| h[k] = 0 }) do |event, activities|
        activities[event["date"]] += event["num_events"]
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def events_by_date(date)
      return Event.none unless can_read_cross_project?

      date_in_time_zone = date.in_time_zone(@contributor_time_instance)

      Event.contributions.where(author_id: contributor.id)
        .where(created_at: date_in_time_zone.beginning_of_day..date_in_time_zone.end_of_day)
        .where(project_id: projects)
        .with_associations
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def starting_year
      @contributor_time_instance.now.years_ago(1).year
    end

    def starting_month
      @contributor_time_instance.today.month
    end

    private

    def can_read_cross_project?
      Ability.allowed?(current_user, :read_cross_project)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def event_created_at(date_from, feature)
      t = Event.arel_table

      # re-running the contributed projects query in each union is expensive, so
      # use IN(project_ids...) instead. It's the intersection of two users so
      # the list will be (relatively) short
      @contributed_project_ids ||= projects.distinct.pluck(:id)
      authed_projects = ProjectFeature
        .with_feature_available_for_user(feature, current_user)
        .where(project_id: @contributed_project_ids)
        .reorder(nil)
        .select(:project_id)

      conditions = t[:created_at].gteq(date_from.beginning_of_day)
        .and(t[:created_at].lteq(@contributor_time_instance.today.end_of_day))
        .and(t[:author_id].eq(contributor.id))

      Event.reorder(nil)
        .select(:created_at)
        .where(conditions)
        .where("events.project_id in (#{authed_projects.to_sql})") # rubocop:disable GitlabSecurity/SqlInjection
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

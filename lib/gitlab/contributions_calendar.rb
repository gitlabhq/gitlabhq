# frozen_string_literal: true

module Gitlab
  class ContributionsCalendar
    include TimeZoneHelper
    include ::Gitlab::Utils::StrongMemoize

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

    def activity_dates
      return {} if projects.empty?

      start_time = @contributor_time_instance.years_ago(1).beginning_of_day
      end_time = @contributor_time_instance.end_of_day

      date_interval = "INTERVAL '#{@contributor_time_instance.utc_offset} seconds'"

      if Feature.enabled?(:contributions_calendar_refactoring, contributor)
        return contributions_between(start_time, end_time).count_by_dates(date_interval)
      end

      # TODO: Remove after feature flag `contributions_calendar_refactoring` is rolled out
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/429648
      # rubocop: disable CodeReuse/ActiveRecord -- will be removed
      # Can't use Event.contributions here because we need to check 3 different
      # project_features for the (currently) 4 different contribution types
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
      # rubocop: enable CodeReuse/ActiveRecord

      events.each_with_object(Hash.new { |h, k| h[k] = 0 }) do |event, activities|
        activities[event["date"]] += event["num_events"]
      end
    end

    def events_by_date(date)
      return Event.none unless can_read_cross_project?

      date_in_time_zone = date.in_time_zone(@contributor_time_instance.time_zone)

      if Feature.enabled?(:contributions_calendar_refactoring, contributor)
        return contributions_between(date_in_time_zone.beginning_of_day, date_in_time_zone.end_of_day).with_associations
      end

      # TODO: Remove after feature flag `contributions_calendar_refactoring` is rolled out
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/429648
      # rubocop: disable CodeReuse/ActiveRecord -- will be removed
      Event.contributions.where(author_id: contributor.id)
        .where(created_at: date_in_time_zone.beginning_of_day..date_in_time_zone.end_of_day)
        .where(project_id: projects)
        .with_associations
      # rubocop: enable CodeReuse/ActiveRecord
    end

    private

    def contributions_between(start_time, end_time)
      # Can't use Event.contributions here because we need to check 3 different
      # project_features for the (currently) 4 different contribution types
      repo_events =
        project_events_created_between(start_time, end_time, features: :repository)
          .for_action(:pushed)

      issue_events =
        project_events_created_between(start_time, end_time, features: :issues)
          .for_issue
          .for_action(%i[created closed])

      mr_events =
        project_events_created_between(start_time, end_time, features: :merge_requests)
          .for_merge_request
          .for_action(%i[merged created closed approved])

      note_events =
        project_events_created_between(start_time, end_time, features: %i[issues merge_requests])
          .for_action(:commented)

      Event.from_union([repo_events, issue_events, mr_events, note_events], remove_duplicates: false)
    end

    def can_read_cross_project?
      Ability.allowed?(current_user, :read_cross_project)
    end

    # rubocop: disable CodeReuse/ActiveRecord -- no need to move this to ActiveRecord model
    def project_events_created_between(start_time, end_time, features:)
      Array(features).reduce(Event.none) do |events, feature|
        events.or(contribution_events(start_time, end_time).where(project_id: authed_projects(feature)))
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def authed_projects(feature)
      strong_memoize("#{feature}_projects") do
        # no need to check features access of current user, if the contributor opted-in
        # to show all private events anyway - otherwise they would get filtered out again
        next contributed_project_ids if contributor.include_private_contributions?

        # rubocop: disable CodeReuse/ActiveRecord -- no need to move this to ActiveRecord model
        ProjectFeature
          .with_feature_available_for_user(feature, current_user)
          .where(project_id: contributed_project_ids)
          .pluck(:project_id)
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord -- no need to move this to ActiveRecord model
    def contributed_project_ids
      # re-running the contributed projects query in each union is expensive, so
      # use IN(project_ids...) instead. It's the intersection of two users so
      # the list will be (relatively) short
      @contributed_project_ids ||= projects.distinct.pluck(:id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def contribution_events(start_time, end_time)
      contributor.events.created_between(start_time, end_time)
    end

    # TODO: Remove after feature flag `contributions_calendar_refactoring` is rolled out
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/429648
    # rubocop: disable CodeReuse/ActiveRecord -- will be removed
    def events_created_between(start_time, end_time, feature)
      # no need to check feature access of current user, if the contributor opted-in
      # to show all private events anyway - otherwise they would get filtered out again
      authed_projects = if contributor.include_private_contributions?
                          contributed_project_ids
                        else
                          ProjectFeature
                            .with_feature_available_for_user(feature, current_user)
                            .where(project_id: contributed_project_ids)
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

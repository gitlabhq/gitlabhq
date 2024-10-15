# frozen_string_literal: true

module Gitlab
  class ContributionsCalendar
    include TimeZoneHelper
    include ::Gitlab::Utils::StrongMemoize

    attr_reader :contributor
    attr_reader :current_user
    attr_reader :groups
    attr_reader :projects

    def initialize(contributor, current_user = nil)
      @contributor = contributor
      @contributor_time_instance = local_timezone_instance(contributor.timezone).now
      @current_user = current_user
      @groups = [] # Overriden in EE
      @projects = ContributedProjectsFinder.new(
        user: @contributor,
        current_user: current_user,
        params: {
          ignore_visibility: @contributor.include_private_contributions?
        }
      ).execute
    end

    def activity_dates
      return {} if groups.blank? && projects.blank?

      start_time = @contributor_time_instance.years_ago(1).beginning_of_day
      end_time = @contributor_time_instance.end_of_day

      date_interval = "INTERVAL '#{@contributor_time_instance.utc_offset} seconds'"

      contributions_between(start_time, end_time).count_by_dates(date_interval)
    end

    def events_by_date(date)
      return Event.none unless can_read_cross_project?

      date_in_time_zone = date.in_time_zone(@contributor_time_instance.time_zone)

      contributions_between(date_in_time_zone.beginning_of_day, date_in_time_zone.end_of_day).with_associations
    end

    private

    def contributions_between(start_time, end_time)
      Event.from_union(
        collect_events_between(start_time, end_time),
        remove_duplicates: false
      )
    end

    def collect_events_between(start_time, end_time)
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

      project_note_events =
        project_events_created_between(start_time, end_time, features: %i[issues merge_requests])
          .for_action(:commented)

      [repo_events, issue_events, mr_events, project_note_events]
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
  end
end

Gitlab::ContributionsCalendar.prepend_mod

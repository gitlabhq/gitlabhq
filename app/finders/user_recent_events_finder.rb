# frozen_string_literal: true

# Get user activity feed for projects common for a user and a logged in user
#
# - current_user: The user viewing the events
#                 WARNING: does not consider project feature visibility!
# - user: The user for which to load the events
# - params:
#   - limit: Number of items that to be returned. Defaults to 20 and limited to 100.
#   - offset: The page of events to return
#   - organization: Organizations::Organization to filter events by
class UserRecentEventsFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include Gitlab::Allowable

  requires_cross_project_access

  attr_reader :current_user, :target_user, :params, :event_filter, :organization, :exclude_transferred_events

  DEFAULT_LIMIT = 20
  MAX_LIMIT = 100

  def initialize(current_user, target_user, event_filter, params = {}, exclude_transferred_events: false)
    @current_user = current_user
    @target_user = target_user
    @organization = params[:organization]
    @params = params.except(:organization)
    @event_filter = event_filter || EventFilter.new(EventFilter::ALL)
    @exclude_transferred_events = exclude_transferred_events
  end

  def execute
    if target_user.is_a? User
      execute_single
    else
      execute_multi
    end
  end

  private

  def execute_single
    return Event.none unless can?(current_user, :read_user_profile, target_user)

    events = filter_transferred_events(target_events)

    event_filter.apply_filter(events
      .with_associations
      .limit_recent(limit, offset)
      .order_created_desc)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute_multi
    users = []
    @target_user.each do |user|
      users.append(user.id) if can?(current_user, :read_user_profile, user)
    end

    return Event.none if users.empty?

    array_data = {
      scope_ids: users,
      scope_model: User,
      mapping_column: :author_id
    }
    query_builder_params = event_filter.in_operator_query_builder_params(array_data)

    query_builder_params[:scope] = filter_by_organization(query_builder_params[:scope]) if organization

    events = Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder
      .new(**query_builder_params)
      .execute

    events = filter_transferred_events(events)
    events
      .limit(limit)
      .offset(offset)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def target_events
    events = Event.where(author: target_user)
    events = filter_by_organization(events) if organization

    events
  end

  # Filter events by organization. Uses LEFT JOINs so the query planner can use
  # index_events_on_author_id_and_id for efficient ORDER BY/LIMIT, then filter
  # by organization as a post-condition.
  def filter_by_organization(events)
    events = events.left_joins(:project, :group, :personal_namespace)

    organization_filter = { organization_id: organization.id }
    events.where(projects: organization_filter)
      .or(events.where(personal_namespace: organization_filter))
      .or(events.where(group: organization_filter))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def filter_transferred_events(events)
    return events unless exclude_transferred_events

    events.excluding_transferred
  end

  def limit
    return DEFAULT_LIMIT unless params[:limit].present? && params[:limit].to_i >= 0

    [params[:limit].to_i, MAX_LIMIT].min
  end

  def offset
    return 0 unless params[:offset].present? && params[:offset].to_i >= 0

    params[:offset].to_i
  end
end

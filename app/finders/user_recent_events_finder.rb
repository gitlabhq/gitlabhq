# frozen_string_literal: true

# Get user activity feed for projects common for a user and a logged in user
#
# - current_user: The user viewing the events
#                 WARNING: does not consider project feature visibility!
# - user: The user for which to load the events
# - params:
#   - limit: Number of items that to be returned. Defaults to 20 and limited to 100.
#   - offset: The page of events to return
class UserRecentEventsFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include Gitlab::Allowable

  requires_cross_project_access

  attr_reader :current_user, :target_user, :params, :event_filter

  DEFAULT_LIMIT = 20
  MAX_LIMIT = 100

  def initialize(current_user, target_user, event_filter, params = {})
    @current_user = current_user
    @target_user = target_user
    @params = params
    @event_filter = event_filter || EventFilter.new(EventFilter::ALL)
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

    event_filter.apply_filter(target_events
      .with_associations
      .limit_recent(limit, params[:offset])
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

    Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder
      .new(**query_builder_params)
      .execute
      .limit(limit)
      .offset(params[:offset] || 0)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def target_events
    Event.where(author: target_user)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def limit
    return DEFAULT_LIMIT unless params[:limit].present?

    [params[:limit].to_i, MAX_LIMIT].min
  end
end

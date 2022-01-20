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
  def execute_optimized_multi(users)
    Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
      scope: Event.reorder(id: :desc),
      array_scope: User.select(:id).where(id: users),
      # Event model has a default scope { reorder(nil) }
      # When a relation is rordered and used as a target when merging scope,
      # its order takes a precedence and _overwrites_ the original scope's order.
      # Thus we have to explicitly provide `reorder` for array_mapping_scope here.
      array_mapping_scope: -> (author_id_expression) { Event.where(Event.arel_table[:author_id].eq(author_id_expression)).reorder(id: :desc) },
      finder_query: -> (id_expression) { Event.where(Event.arel_table[:id].eq(id_expression)) }
    )
    .execute
    .limit(limit)
    .offset(params[:offset] || 0)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def execute_multi
    users = []
    @target_user.each do |user|
      users.append(user.id) if can?(current_user, :read_user_profile, user)
    end

    return Event.none if users.empty?

    if event_filter.filter == EventFilter::ALL
      execute_optimized_multi(users)
    else
      event_filter.apply_filter(Event.where(author: users).limit_recent(limit, params[:offset] || 0))
    end
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

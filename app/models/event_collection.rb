# frozen_string_literal: true

# A collection of events to display in an event list.
#
# An EventCollection is meant to be used for displaying events to a user (e.g.
# in a controller), it's not suitable for building queries that are used for
# building other queries.
class EventCollection
  include Gitlab::Utils::StrongMemoize

  # To prevent users from putting too much pressure on the database by cycling
  # through thousands of events we put a limit on the number of pages.
  MAX_PAGE = 10

  # projects - An ActiveRecord::Relation object that returns the projects for
  #            which to retrieve events.
  # filter - An EventFilter instance to use for filtering events.
  def initialize(projects, limit: 20, offset: 0, filter: nil, groups: nil)
    @projects = projects
    @limit = limit
    @offset = offset
    @filter = filter
    @groups = groups
  end

  # Returns an Array containing the events.
  def to_a
    return [] if current_page > MAX_PAGE

    relation = if groups
                 project_and_group_events
               else
                 project_events
               end

    relation = paginate_events(relation)
    relation.with_associations.to_a
  end

  def all_project_events
    Event.from_union([project_events]).recent
  end

  private

  def project_events
    in_operator_optimized_relation('project_id', projects)
  end

  def group_events
    in_operator_optimized_relation('group_id', groups)
  end

  def project_and_group_events
    Event.from_union([project_events, group_events]).recent
  end

  def in_operator_optimized_relation(parent_column, parents)
    scope = filtered_events
    array_scope = parents.select(:id)
    array_mapping_scope = -> (parent_id_expression) { Event.where(Event.arel_table[parent_column].eq(parent_id_expression)).reorder(id: :desc) }
    finder_query = -> (id_expression) { Event.where(Event.arel_table[:id].eq(id_expression)) }

    Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder
      .new(
        scope: scope,
        array_scope: array_scope,
        array_mapping_scope: array_mapping_scope,
        finder_query: finder_query
      )
      .execute
  end

  def filtered_events
    @filter ? @filter.apply_filter(base_relation) : base_relation
  end

  def paginate_events(events)
    events.limit(@limit).offset(@offset)
  end

  def base_relation
    # We want to have absolute control over the event queries being built, thus
    # we're explicitly opting out of any default scopes that may be set.
    Event.unscoped.recent
  end

  def current_page
    (@offset / @limit) + 1
  end

  def projects
    @projects.except(:order)
  end

  def groups
    strong_memoize(:groups) do
      groups.except(:order) if @groups
    end
  end
end

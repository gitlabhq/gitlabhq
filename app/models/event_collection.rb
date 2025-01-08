# frozen_string_literal: true

# A collection of events to display in an event list.
#
# An EventCollection is meant to be used for displaying events to a user (e.g.
# in a controller), it's not suitable for building queries that are used for
# building other queries.
class EventCollection
  include Gitlab::Utils::StrongMemoize

  attr_reader :filter

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
    @filter = filter || EventFilter.new(EventFilter::ALL)
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
    in_operator_optimized_relation('project_id', projects, Project)
  end

  def group_events
    in_operator_optimized_relation('group_id', groups, Namespace)
  end

  def project_and_group_events
    if EventFilter::PROJECT_ONLY_EVENT_TYPES.include?(filter.filter)
      project_events
    else
      Event.from_union([project_events, group_events]).recent
    end
  end

  def in_operator_optimized_relation(parent_column, parents, parent_model)
    parent_id_column = parent_model.arel_table[:id]

    array_data = {
      scope_ids: parents.pluck(parent_id_column),
      scope_model: parent_model,
      mapping_column: parent_column
    }
    query_builder_params = filter.in_operator_query_builder_params(array_data)

    Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder
      .new(**query_builder_params)
      .execute
      .limit(@limit + @offset)
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

EventCollection.prepend_mod

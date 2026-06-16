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
  # preserve_projects_order - If true, retains the :order clause for projects.
  def initialize(
    projects,
    limit: 20,
    offset: 0,
    filter: nil,
    groups: nil,
    preserve_projects_order: false,
    transfer_options: {}
  )
    @projects = projects
    @limit = limit
    @offset = offset
    @filter = filter || EventFilter.new(EventFilter::ALL)
    @groups = groups
    @preserve_projects_order = preserve_projects_order
    @current_group_id = transfer_options[:current_group_id]
    @ancestor_group_ids = transfer_options[:ancestor_group_ids]
    @exclude_transferred_events = transfer_options.fetch(:exclude_transferred_events, false)
  end

  # Returns an Array containing the events.
  def to_a
    return [] if current_page > MAX_PAGE

    relation = if groups
                 project_and_group_events
               elsif current_group_transfer_context?
                 project_and_current_group_transfer_events
               else
                 project_and_ancestor_group_transfer_events
               end

    relation = exclude_transferred_events(relation) if @exclude_transferred_events
    relation = paginate_events(relation)
    relation.with_associations.to_a
  end

  def all_project_events
    Event.from_union([project_events]).recent
  end

  private

  def project_events
    materialize_event_rows(in_operator_optimized_relation('project_id', projects, Project))
  end

  def group_events
    materialize_event_rows(in_operator_optimized_relation('group_id', groups, Namespace))
  end

  def project_and_group_events
    if EventFilter::PROJECT_ONLY_EVENT_TYPES.include?(filter.filter)
      project_events
    else
      Event.from_union([project_events, group_events]).recent
    end
  end

  def project_and_ancestor_group_transfer_events
    return project_events unless @ancestor_group_ids && filter.include_transferred_events?

    Event.from_union([project_events, ancestor_group_transfer_events]).recent
  end

  def project_and_current_group_transfer_events
    Event.from_union(
      [
        non_transferred_project_events,
        transferred_direct_project_events,
        current_group_transfer_events
      ],
      remove_duplicates: false
    ).recent
  end

  def in_operator_optimized_relation(parent_column, parents, parent_model)
    parent_id_column = parent_model.arel_table[:id]
    scope_ids = parents.pluck(parent_id_column)

    if filter.active?(EventFilter::ALL) && scope_ids.one?
      return Event.where(parent_column => scope_ids.first).recent.limit(@limit + @offset)
    end

    array_data = {
      scope_ids: scope_ids,
      scope_model: parent_model,
      mapping_column: parent_column
    }
    query_builder_params = filter.in_operator_query_builder_params(array_data)

    Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder
      .new(**query_builder_params)
      .execute
      .limit(@limit + @offset)
  end

  def materialize_event_rows(events)
    Event.where(id: events.reselect(:id)).recent.limit(@limit + @offset)
  end

  def non_transferred_project_events
    project_events.where.not(action: Event.actions[:transferred])
      .recent
  end

  def exclude_transferred_events(events)
    events.where.not(action: Event.actions[:transferred])
  end

  def ancestor_group_transfer_events
    Event.transferred_action
      .where(group_id: @ancestor_group_ids.select(:id))
      .where(project_id: nil, target_type: Group.name)
  end

  def current_group_transfer_events
    strong_memoize(:current_group_transfer_events) do
      Event.transferred_action
        .where(project_id: nil, group_id: current_group_and_direct_subgroups.select(:id))
        .recent
        .limit(@limit + @offset)
    end
  end

  def transferred_direct_project_events
    strong_memoize(:transferred_direct_project_events) do
      Event.transferred_action
        .for_project
        .where(project_id: direct_projects_in_current_group.select(:id))
        .recent
        .limit(@limit + @offset)
    end
  end

  def direct_projects_in_current_group
    Project.where(namespace_id: @current_group_id)
  end

  def current_group_and_direct_subgroups
    strong_memoize(:current_group_and_direct_subgroups) do
      Group.where(id: @current_group_id).or(direct_subgroups_in_current_group)
    end
  end

  def direct_subgroups_in_current_group
    Group.where(parent_id: @current_group_id)
  end

  def current_group_transfer_context?
    @current_group_id && filter.include_transferred_events?
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
    @preserve_projects_order ? @projects : @projects.except(:order)
  end

  def groups
    strong_memoize(:groups) do
      @groups&.except(:order)
    end
  end
end

EventCollection.prepend_mod

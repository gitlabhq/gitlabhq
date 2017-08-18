# A collection of events to display in an event list.
#
# An EventCollection is meant to be used for displaying events to a user (e.g.
# in a controller), it's not suitable for building queries that are used for
# building other queries.
class EventCollection
  # To prevent users from putting too much pressure on the database by cycling
  # through thousands of events we put a limit on the number of pages.
  MAX_PAGE = 10

  # projects - An ActiveRecord::Relation object that returns the projects for
  #            which to retrieve events.
  # filter - An EventFilter instance to use for filtering events.
  def initialize(projects, limit: 20, offset: 0, filter: nil)
    @projects = projects
    @limit = limit
    @offset = offset
    @filter = filter
  end

  # Returns an Array containing the events.
  def to_a
    return [] if current_page > MAX_PAGE

    relation = if Gitlab::Database.join_lateral_supported?
                 relation_with_join_lateral
               else
                 relation_without_join_lateral
               end

    relation.with_associations.to_a
  end

  private

  # Returns the events relation to use when JOIN LATERAL is not supported.
  #
  # This relation simply gets all the events for all authorized projects, then
  # limits that set.
  def relation_without_join_lateral
    events = filtered_events.in_projects(projects)

    paginate_events(events)
  end

  # Returns the events relation to use when JOIN LATERAL is supported.
  #
  # This relation is built using JOIN LATERAL, producing faster queries than a
  # regular LIMIT + OFFSET approach.
  def relation_with_join_lateral
    projects_for_lateral = projects.select(:id).to_sql

    lateral = filtered_events
      .limit(limit_for_join_lateral)
      .where('events.project_id = projects_for_lateral.id')
      .to_sql

    # The outer query does not need to re-apply the filters since the JOIN
    # LATERAL body already takes care of this.
    outer = base_relation
      .from("(#{projects_for_lateral}) projects_for_lateral")
      .joins("JOIN LATERAL (#{lateral}) AS #{Event.table_name} ON true")

    paginate_events(outer)
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

  def limit_for_join_lateral
    # Applying the OFFSET on the inside of a JOIN LATERAL leads to incorrect
    # results. To work around this we need to increase the inner limit for every
    # page.
    #
    # This means that on page 1 we use LIMIT 20, and an outer OFFSET of 0. On
    # page 2 we use LIMIT 40 and an outer OFFSET of 20.
    @limit + @offset
  end

  def current_page
    (@offset / @limit) + 1
  end

  def projects
    @projects.except(:order)
  end
end

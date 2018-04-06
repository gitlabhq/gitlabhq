class EpicsFinder < IssuableFinder
  def klass
    Epic
  end

  def execute
    raise ArgumentError, 'group_id argument is missing' unless group

    items = init_collection
    items = by_created_at(items)
    items = by_search(items)
    items = by_author(items)
    items = by_timeframe(items)
    items = by_label(items)

    sort(items)
  end

  def row_count
    count = execute.count

    # When filtering by multiple labels, count returns a hash of
    # records grouped by id - so we just have to get length of the Hash.
    # Once we have state for epics, we can use default issuables row_count
    # method.
    count.is_a?(Hash) ? count.length : count
  end

  # we don't have states for epics for now this method (#4017)
  def count_by_state
    {
      all: row_count
    }
  end

  def group
    return nil unless params[:group_id]
    return @group if defined?(@group)

    group = Group.find(params[:group_id])
    group = nil unless Ability.allowed?(current_user, :read_epic, group)

    @group = group
  end

  def init_collection
    groups = groups_user_can_read_epics(group.self_and_descendants)

    Epic.where(group: groups)
  end

  private

  def groups_user_can_read_epics(groups)
    DeclarativePolicy.user_scope do
      groups.select { |g| Ability.allowed?(current_user, :read_epic, g) }
    end
  end

  def by_timeframe(items)
    return items unless params[:start_date] && params[:end_date]

    end_date = params[:end_date].to_datetime.end_of_day
    start_date = params[:start_date].to_datetime.beginning_of_day

    items
      .where('epics.start_date is not NULL or epics.end_date is not NULL')
      .where('epics.start_date is NULL or epics.start_date <= ?', end_date)
      .where('epics.end_date is NULL or epics.end_date >= ?', start_date)
  rescue ArgumentError
    items
  end
end

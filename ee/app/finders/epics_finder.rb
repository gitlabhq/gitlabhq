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
    items = by_state(items)
    items = by_label(items)

    sort(items)
  end

  def group
    return nil unless params[:group_id]
    return @group if defined?(@group)

    group = Group.find(params[:group_id])
    group = nil unless Ability.allowed?(current_user, :read_epic, group)

    @group = group
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def init_collection
    groups = groups_user_can_read_epics(group.self_and_descendants)

    Epic.where(group: groups)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def count_key(value)
    if Gitlab.rails5?
      Array(value).last.to_sym
    else
      Epic.states.invert[Array(value).last].to_sym
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def groups_user_can_read_epics(groups)
    groups = Gitlab::GroupPlansPreloader.new.preload(groups)

    DeclarativePolicy.user_scope do
      groups.select { |g| Ability.allowed?(current_user, :read_epic, g) }
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
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
  # rubocop: enable CodeReuse/ActiveRecord
end

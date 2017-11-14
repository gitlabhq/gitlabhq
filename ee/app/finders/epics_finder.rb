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
    items = by_iids(items)

    sort(items)
  end

  def row_count
    execute.count
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
    group.epics
  end
end

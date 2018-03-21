# Search for milestones
#
# params - Hash
#   project_ids: Array of project ids or single project id.
#   group_ids: Array of group ids or single group id.
#   order - Orders by field default due date asc.
#   title - filter by title.
#   state - filters by state.

class MilestonesFinder
  include FinderMethods

  attr_reader :params, :project_ids, :group_ids

  def initialize(params = {})
    @project_ids = Array(params[:project_ids])
    @group_ids = Array(params[:group_ids])
    @params = params
  end

  def execute
    return Milestone.none if project_ids.empty? && group_ids.empty?

    items = Milestone.all
    items = by_groups_and_projects(items)
    items = by_title(items)
    items = by_state(items)

    order(items)
  end

  private

  def by_groups_and_projects(items)
    items.for_projects_and_groups(project_ids, group_ids)
  end

  def by_title(items)
    if params[:title]
      items.where(title: params[:title])
    else
      items
    end
  end

  def by_state(items)
    Milestone.filter_by_state(items, params[:state])
  end

  def order(items)
    order_statement = Gitlab::Database.nulls_last_order('due_date', 'ASC')
    items.reorder(order_statement).order('title ASC')
  end
end

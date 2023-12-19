# frozen_string_literal: true

# Search for milestones
#
# params - Hash
#   ids - filters by id.
#   project_ids: Array of project ids or single project id or ActiveRecord relation.
#   group_ids: Array of group ids or single group id or ActiveRecord relation.
#   order - Orders by field default due date asc.
#   title - filter by title.
#   state - filters by state.
#   start_date & end_date - filters by timeframe (see TimeFrameFilter)
#   containing_date - filters by point in time (see TimeFrameFilter)

class MilestonesFinder
  include FinderMethods
  include TimeFrameFilter
  include UpdatedAtFilter

  attr_reader :params

  EXPIRED_LAST_SORTS = %i[expired_last_due_date_asc expired_last_due_date_desc].freeze

  def initialize(params = {})
    @params = params
  end

  def execute
    items = Milestone.all
    items = by_ids_or_title(items)
    items = by_groups_and_projects(items)
    items = by_search_title(items)
    items = by_search(items)
    items = by_state(items)
    items = by_timeframe(items)
    items = containing_date(items)
    items = by_updated_at(items)
    items = by_iids(items)

    order(items)
  end

  private

  def by_ids_or_title(items)
    return items if params[:ids].blank? && params[:title].blank?
    return items.id_in(params[:ids]) if params[:ids].present? && params[:title].blank?
    return items.with_title(params[:title]) if params[:ids].blank? && params[:title].present?

    items.with_ids_or_title(ids: params[:ids], title: params[:title])
  end

  def by_groups_and_projects(items)
    items.for_projects_and_groups(params[:project_ids], params[:group_ids])
  end

  def by_search_title(items)
    if params[:search_title].present?
      items.search_title(params[:search_title])
    else
      items
    end
  end

  def by_search(items)
    return items if params[:search].blank?

    items.search(params[:search])
  end

  def by_state(items)
    Milestone.filter_by_state(items, params[:state])
  end

  def order(items)
    sort_by = params[:sort].presence || :due_date_asc

    if sort_by_expired_last?(sort_by)
      items.sort_with_expired_last(sort_by)
    else
      items.sort_by_attribute(sort_by)
    end
  end

  def sort_by_expired_last?(sort_by)
    EXPIRED_LAST_SORTS.include?(sort_by)
  end

  def by_iids(items)
    return items unless params[:iids].present? && !params[:include_ancestors]

    items.by_iid(params[:iids])
  end
end

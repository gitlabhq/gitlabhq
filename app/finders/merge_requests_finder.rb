# Finders::MergeRequest class
#
# Used to filter MergeRequests collections by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     scope: 'created_by_me' or 'assigned_to_me' or 'all'
#     state: 'open', 'closed', 'merged', 'locked', or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_title: string
#     author_id: integer
#     assignee_id: integer
#     search: string
#     label_name: string
#     sort: string
#     non_archived: boolean
#     my_reaction_emoji: string
#     source_branch: string
#     target_branch: string
#     created_after: datetime
#     created_before: datetime
#     updated_after: datetime
#     updated_before: datetime
#
class MergeRequestsFinder < IssuableFinder
  def self.scalar_params
    @scalar_params ||= super + [:wip]
  end

  def klass
    MergeRequest
  end

  def filter_items(_items)
    items = by_source_branch(super)
    items = by_wip(items)
    by_target_branch(items)
  end

  private

  def source_branch
    @source_branch ||= params[:source_branch].presence
  end

  def by_source_branch(items)
    return items unless source_branch

    items.where(source_branch: source_branch)
  end

  def target_branch
    @target_branch ||= params[:target_branch].presence
  end

  def by_target_branch(items)
    return items unless target_branch

    items.where(target_branch: target_branch)
  end

  def item_project_ids(items)
    items&.reorder(nil)&.select(:target_project_id)
  end

  def by_wip(items)
    if params[:wip] == 'yes'
      items.where(wip_match(items.arel_table))
    elsif params[:wip] == 'no'
      items.where.not(wip_match(items.arel_table))
    else
      items
    end
  end

  def wip_match(table)
    table[:title].matches('WIP:%')
        .or(table[:title].matches('WIP %'))
        .or(table[:title].matches('[WIP]%'))
  end
end

# frozen_string_literal: true

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
#     release_tag: string
#     author_id: integer
#     author_username: string
#     assignee_id: integer
#     search: string
#     in: 'title', 'description', or a string joining them with comma
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
  include MergedAtFilter

  def self.scalar_params
    @scalar_params ||= super + [:wip, :draft, :target_branch, :merged_after, :merged_before, :approved_by_ids]
  end

  def self.array_params
    @array_params ||= super.merge(approved_by_usernames: [])
  end

  def klass
    MergeRequest
  end

  def filter_items(_items)
    items = by_commit(super)
    items = by_deployment(items)
    items = by_source_branch(items)
    items = by_draft(items)
    items = by_target_branch(items)
    items = by_merged_at(items)
    items = by_approvals(items)
    by_source_project_id(items)
  end

  private

  def by_commit(items)
    return items unless params[:commit_sha].presence

    items.by_commit_sha(params[:commit_sha])
  end

  def source_branch
    @source_branch ||= params[:source_branch].presence
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_source_branch(items)
    return items unless source_branch

    items.where(source_branch: source_branch)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def target_branch
    @target_branch ||= params[:target_branch].presence
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_target_branch(items)
    return items unless target_branch

    items.where(target_branch: target_branch)
  end

  def source_project_id
    @source_project_id ||= params[:source_project_id].presence
  end

  def by_source_project_id(items)
    return items unless source_project_id

    items.where(source_project_id: source_project_id)
  end

  def by_draft(items)
    draft_param = params[:draft] || params[:wip]

    if draft_param == 'yes'
      items.where(wip_match(items.arel_table))
    elsif draft_param == 'no'
      items.where.not(wip_match(items.arel_table))
    else
      items
    end
  end

  # WIP is deprecated in favor of Draft. Currently both options are supported
  def wip_match(table)
    items =
      table[:title].matches('WIP:%')
        .or(table[:title].matches('WIP %'))
        .or(table[:title].matches('[WIP]%'))

    # Let's keep this FF around until https://gitlab.com/gitlab-org/gitlab/-/issues/232999
    # is implemented
    return items unless Feature.enabled?(:merge_request_draft_filter, default_enabled: true)

    items
      .or(table[:title].matches('Draft - %'))
      .or(table[:title].matches('Draft:%'))
      .or(table[:title].matches('[Draft]%'))
      .or(table[:title].matches('(Draft)%'))
  end

  def by_deployment(items)
    return items unless deployment_id

    items.includes(:deployment_merge_requests)
         .where(deployment_merge_requests: { deployment_id: deployment_id })
  end

  def deployment_id
    @deployment_id ||= params[:deployment_id].presence
  end

  # Filter by merge requests that had been approved by specific users
  # rubocop: disable CodeReuse/Finder
  def by_approvals(items)
    MergeRequests::ByApprovalsFinder
      .new(params[:approved_by_usernames], params[:approved_by_ids])
      .execute(items)
  end
  # rubocop: enable CodeReuse/Finder

  def items_assigned_to(items, user)
    MergeRequest.from_union([super, items.reviewer_assigned_to(user)])
  end
end

MergeRequestsFinder.prepend_if_ee('EE::MergeRequestsFinder')

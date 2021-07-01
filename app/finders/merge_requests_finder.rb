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
    @scalar_params ||= super + [
      :approved_by_ids,
      :deployed_after,
      :deployed_before,
      :draft,
      :environment,
      :merged_after,
      :merged_before,
      :reviewer_id,
      :reviewer_username,
      :target_branch,
      :wip
    ]
  end

  def self.array_params
    @array_params ||= super.merge(approved_by_usernames: [])
  end

  def klass
    MergeRequest
  end

  def params_class
    MergeRequestsFinder.const_get(:Params, false) # rubocop: disable CodeReuse/Finder
  end

  def filter_items(_items)
    items = by_commit(super)
    items = by_source_branch(items)
    items = by_draft(items)
    items = by_target_branch(items)
    items = by_merged_at(items)
    items = by_approvals(items)
    items = by_deployments(items)
    items = by_reviewer(items)

    by_source_project_id(items)
  end

  def filter_negated_items(items)
    items = super(items)
    items = by_negated_reviewer(items)
    items = by_negated_approved_by(items)
    by_negated_target_branch(items)
  end

  private

  def by_commit(items)
    return items unless params[:commit_sha].presence

    items.by_related_commit_sha(params[:commit_sha])
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
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_negated_target_branch(items)
    return items unless not_params[:target_branch]

    items.where.not(target_branch: not_params[:target_branch])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_negated_approved_by(items)
    return items unless not_params[:approved_by_usernames]

    items.not_approved_by_users_with_usernames(not_params[:approved_by_usernames])
  end

  def source_project_id
    @source_project_id ||= params[:source_project_id].presence
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_source_project_id(items)
    return items unless source_project_id

    items.where(source_project_id: source_project_id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
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
  # rubocop: enable CodeReuse/ActiveRecord

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

  # Filter by merge requests that had been approved by specific users
  # rubocop: disable CodeReuse/Finder
  def by_approvals(items)
    MergeRequests::ByApprovalsFinder
      .new(params[:approved_by_usernames], params[:approved_by_ids])
      .execute(items)
  end
  # rubocop: enable CodeReuse/Finder

  def by_deployments(items)
    env = params[:environment]
    before = params[:deployed_before]
    after = params[:deployed_after]
    id = params[:deployment_id]

    return items if !env && !before && !after && !id

    # Each filter depends on the same JOIN+WHERE. To prevent this JOIN+WHERE
    # from being duplicated for every filter, we only produce it once. The
    # filter methods in turn expect the JOIN+WHERE to already be present.
    #
    # This approach ensures that query performance doesn't degrade as the number
    # of deployment related filters increases.
    deploys = DeploymentMergeRequest.join_deployments_for_merge_requests
    deploys = deploys.by_deployment_id(id) if id
    deploys = deploys.deployed_to(env) if env
    deploys = deploys.deployed_before(before) if before
    deploys = deploys.deployed_after(after) if after

    items.where_exists(deploys)
  end

  def by_reviewer(items)
    return items unless params.reviewer_id? || params.reviewer_username?

    if params.filter_by_no_reviewer?
      items.no_review_requested
    elsif params.filter_by_any_reviewer?
      items.review_requested
    elsif params.reviewer
      items.review_requested_to(params.reviewer)
    else # reviewer not found
      items.none
    end
  end

  def by_negated_reviewer(items)
    return items unless not_params.reviewer_id? || not_params.reviewer_username?

    if not_params.reviewer.present?
      items.no_review_requested_to(not_params.reviewer)
    else # reviewer not found
      items.none
    end
  end
end

MergeRequestsFinder.prepend_mod_with('MergeRequestsFinder')

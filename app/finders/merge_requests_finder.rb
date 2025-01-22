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
#     merged_without_event_source: boolean
#     my_reaction_emoji: string
#     source_branch: string
#     target_branch: string
#     created_after: datetime
#     created_before: datetime
#     updated_after: datetime
#     updated_before: datetime
#
class MergeRequestsFinder < IssuableFinder
  extend ::Gitlab::Utils::Override

  include MergedAtFilter
  include MergeUserFilter

  def self.scalar_params
    @scalar_params ||= super + [
      :approved,
      :approved_by_ids,
      :deployed_after,
      :deployed_before,
      :draft,
      :environment,
      :merge_user_id,
      :merge_user_username,
      :merged_after,
      :merged_before,
      :reviewer_id,
      :reviewer_username,
      :review_state,
      :source_branch,
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
    items = by_merge_user(items)
    items = by_merged_at(items)
    items = by_approvals(items)
    items = by_deployments(items)
    items = by_reviewer(items)
    items = by_review_state(items)
    items = by_source_project_id(items)
    items = by_resource_event_state(items)
    items = by_assignee_or_reviewer(items)
    items = by_blob_path(items)

    by_approved(items)
  end

  def filter_negated_items(items)
    items = super(items)
    items = by_negated_reviewer(items)
    items = by_negated_approved_by(items)
    items = by_negated_target_branch(items)
    items = by_negated_review_states(items)
    by_negated_source_branch(items)
  end

  private

  override :sort
  def sort(items)
    items = super(items)

    return items unless use_grouping_columns?

    grouping_columns = klass.grouping_columns(params[:sort])
    items.group(grouping_columns) # rubocop:disable CodeReuse/ActiveRecord
  end

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

  def by_negated_source_branch(items)
    return items unless not_params[:source_branch]

    items.where.not(source_branch: not_params[:source_branch])
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

  def by_resource_event_state(items)
    return items unless params[:merged_without_event_source].present?

    items.merged_without_state_event_source
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_draft(items)
    draft_param = Gitlab::Utils.to_boolean(params.fetch(:draft) { params.fetch(:wip, nil) })
    return items if draft_param.nil?

    if draft_param
      items.where(draft_match(items.arel_table))
    else
      items.where.not(draft_match(items.arel_table))
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def draft_match(table)
    table[:title].matches('Draft - %')
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

  def by_approved(items)
    approved_param = Gitlab::Utils.to_boolean(params.fetch(:approved, nil))
    return items if approved_param.nil? || Feature.disabled?(:mr_approved_filter, type: :ops)

    if approved_param
      items.with_approvals
    else
      items.without_approvals
    end
  end

  def by_deployments(items)
    env = params[:environment]
    before = parse_datetime(params[:deployed_before])
    after = parse_datetime(params[:deployed_after])
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
      items.review_requested_to(params.reviewer, params.review_state)
    else # reviewer not found
      items.none
    end
  end

  def by_review_state(items)
    return items unless params.review_state.present?
    return items if params.reviewer_id? || params.reviewer_username?

    items.review_states(params.review_state)
  end

  def by_negated_review_states(items)
    return items unless params.not_review_states.present?

    items.no_review_states(params.not_review_states)
  end

  def by_negated_reviewer(items)
    return items unless not_params.reviewer_id? || not_params.reviewer_username?

    if not_params.reviewer.present?
      items.no_review_requested_to(not_params.reviewer)
    else # reviewer not found
      items.none
    end
  end

  def by_assignee_or_reviewer(items)
    return items unless current_user&.merge_request_dashboard_enabled?
    return items unless params.assigned_user

    items.assignee_or_reviewer(
      params.assigned_user,
      params.assigned_review_states,
      params.reviewer_review_states
    )
  end

  def by_blob_path(items)
    blob_path = params[:blob_path]

    return items unless blob_path
    return items.none unless params.project

    items.by_blob_path(blob_path)
  end

  def parse_datetime(input)
    # NOTE: Input from GraphQL query is a Time object already.
    #   Just return DateTime object for consistency instead of trying to parse it.
    return input.to_datetime if input.is_a?(Time)

    # To work around http://www.ruby-lang.org/en/news/2021/11/15/date-parsing-method-regexp-dos-cve-2021-41817/
    DateTime.parse(input.byteslice(0, 128)) if input
  rescue Date::Error
    nil
  end

  def use_grouping_columns?
    return false unless params[:sort].present?

    params[:approved_by_usernames].present? || params[:approved_by_ids].present?
  end
end

MergeRequestsFinder.prepend_mod_with('MergeRequestsFinder')

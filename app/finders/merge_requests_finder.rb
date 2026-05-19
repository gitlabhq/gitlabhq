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
#     review_states: 'unreviewed', 'reviewed', 'requested_changes' or 'approved'
#     not:
#       only_reviewer: boolean
#       reviewer_username: string
#       review_states: 'unreviewed', 'reviewed', 'requested_changes' or 'approved'
#     or:
#       only_reviewer_username: boolean
#       reviewer_wildcard: string
#       review_states: 'unreviewed', 'reviewed', 'requested_changes' or 'approved'
#
class MergeRequestsFinder < IssuableFinder
  extend ::Gitlab::Utils::Override

  include MergedAtFilter
  include MergeUserFilter

  # The optimization is activated only when we can satisfy the
  # full index prefix of:
  #
  #   idx_mrs_on_target_id_and_created_at_and_state_id
  #   (target_project_id, state_id, created_at, id)
  #
  # A specific state_id equality filter is therefore required (see
  # specific_state_filter?) so that PostgreSQL can pin the first two columns
  # before ranging over (created_at, id).
  IN_OPERATOR_OPTIMIZABLE_SORTS = %w[created_at_asc created_at_desc].freeze

  # The complete set of params that are safe to have present when the
  # in-operator optimization is active.  Any param outside this list adds a
  # WHERE clause beyond what idx_mrs_on_target_id_and_created_at_and_state_id
  # covers and therefore blocks the optimization.
  #
  # Derived directly from the params shape the group MR API endpoint sends:
  #   state, sort/order_by, group_id, include_subgroups      - handled separately
  #   page, per_page, non_archived
  #   with_labels_details, with_merge_status_recheck, attempt_group_search_optimizations - not query filters
  OPTIMIZABLE_FILTER_PARAMS = %i[
    state
    sort order_by
    group_id include_subgroups
    page per_page
    non_archived
    with_labels_details
    with_merge_status_recheck
    attempt_group_search_optimizations
  ].freeze

  def self.scalar_params
    @scalar_params ||= super + [
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

  override :execute
  def execute
    @group_mr_in_optimization_applied = false
    return super unless use_in_operator_optimization?

    result = execute_with_in_operator_optimization
    @group_mr_in_optimization_applied = true

    Gitlab::AppLogger.info({
      message: "MergeRequestsFinder: in-operator optimization applied",
      group_id: params.group.id,
      sort: params[:sort],
      state: params[:state]
    })

    result
  rescue Gitlab::Pagination::Keyset::UnsupportedScopeOrder => e
    # Fall back to the standard execution if the keyset order is not supported
    @group_mr_in_optimization_applied = false

    Gitlab::AppLogger.info({
      message: "MergeRequestsFinder: in-operator optimization fell back due to UnsupportedScopeOrder",
      group_id: params.group&.id,
      Labkit::Fields::ERROR_MESSAGE => e.message
    })

    super
  end

  def group_mr_in_optimization_applied?
    @group_mr_in_optimization_applied
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
    items = by_no_review_requested_or_only_user(items)
    items = by_review_states_or_no_reviewer(items)
    by_valid_or_no_reviewers(items)
  end

  def filter_negated_items(items)
    items = super(items)
    items = by_negated_reviewer(items)
    items = by_negated_approved_by(items)
    items = by_negated_target_branch(items)
    items = by_negated_review_states(items)
    items = by_negated_only_reviewer(items)
    by_negated_source_branch(items)
  end

  private

  def use_in_operator_optimization?
    return false unless Feature.enabled?(:group_mr_in_operator_optimization, params.group)

    group_present = params.group?
    include_subgroups_set = params[:include_subgroups].present?
    sort_optimizable = IN_OPERATOR_OPTIMIZABLE_SORTS.include?(params[:sort].to_s)
    specific_state = specific_state_filter?
    no_active_filters = !any_active_filters?

    unless group_present && include_subgroups_set && sort_optimizable && specific_state && no_active_filters
      Gitlab::AppLogger.info({
        message: "MergeRequestsFinder: in-operator optimization skipped",
        group_id: params.group&.id,
        group_present: group_present,
        include_subgroups_set: include_subgroups_set,
        sort_optimizable: sort_optimizable,
        specific_state: specific_state,
        no_active_filters: no_active_filters
      })

      return false
    end

    true
  end

  # Returns true only when params[:state] resolves to a single state_id equality
  # predicate.  'all' and a blank value produce no WHERE state_id = ? clause,
  # leaving the second column of the index prefix unused and forcing a broader
  # range scan over every state for each project.
  def specific_state_filter?
    %w[opened closed merged locked].include?(params[:state].to_s)
  end

  # Returns true if any param outside OPTIMIZABLE_FILTER_PARAMS has a value, or
  # if the not:/or: sub-hashes contain any non-blank values.  In that case the
  # query adds WHERE clauses the index cannot satisfy and the standard execution
  # path is faster.
  def any_active_filters?
    params.to_h.deep_symbolize_keys.except(*OPTIMIZABLE_FILTER_PARAMS, :not,
      :or).values.any? { |v| filter_value_present?(v) } ||
      params[:not].to_h.values.any? { |v| filter_value_present?(v) } ||
      params[:or].to_h.values.any? { |v| filter_value_present?(v) }
  end

  def filter_value_present?(value)
    value.is_a?(ActiveRecord::Relation) || value.present?
  end

  def execute_with_in_operator_optimization
    # Temporarily skip the parent (project IN subquery) filter so we can hand off
    # the per-project iteration to InOperatorOptimization::QueryBuilder. The
    # project scope is enforced via `array_scope` instead, which is already
    # restricted to projects that are visible to the current user.
    @skip_parent_filter = true
    non_archived = params.delete(:non_archived).present?

    items = init_collection
    items = filter_items(items)
    items = filter_negated_items(items) if should_filter_negated_args?
    items = by_search(items)
    items = sort(items)

    projects = non_archived ? accessible_projects.non_archived : accessible_projects

    Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
      scope: items,
      array_scope: projects.select(:id),
      array_mapping_scope: MergeRequest.method(:in_optimization_array_mapping_scope),
      finder_query: MergeRequest.method(:in_optimization_finder_query)
    ).execute
  ensure
    @skip_parent_filter = false
    params[:non_archived] = true if non_archived
  end

  override :by_parent
  def by_parent(items)
    return items if @skip_parent_filter

    super
  end

  override :sort
  def sort(items)
    items = super(items)

    return items unless use_grouping_columns?

    grouping_columns = klass.grouping_columns(params[:sort])
    items.group(grouping_columns) # rubocop:disable CodeReuse/ActiveRecord
  end

  def by_author(items)
    MergeRequests::AuthorFilter.new(
      current_user: current_user,
      params: params
    ).filter(items)
  end

  def by_commit(items)
    return items unless params[:commit_sha].presence
    return items unless params.project

    items.by_related_commit_sha(params.project, params[:commit_sha])
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
    draft_param = Gitlab::Utils.to_boolean(params[:draft].nil? ? params[:wip] : params[:draft])
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

    items.review_states(params.review_state, params.ignored_reviewer)
  end

  def by_negated_review_states(items)
    return items unless params.not_review_states.present?

    items.no_review_states(params.not_review_states, params.ignored_reviewer)
  end

  def by_negated_reviewer(items)
    return items if not_params[:only_reviewer]
    return items unless not_params.reviewer_id? || not_params.reviewer_username?

    if not_params.reviewer.present?
      items.no_review_requested_to(not_params.reviewer)
    else # reviewer not found
      items.none
    end
  end

  def by_negated_only_reviewer(items)
    return items unless not_params[:only_reviewer]
    return items unless not_params.reviewer_id? || not_params.reviewer_username?

    items.not_only_reviewer(not_params.reviewer)
  end

  def by_review_states_or_no_reviewer(items)
    return items unless or_params&.fetch(:reviewer_wildcard, false).present?
    return items unless or_params[:reviewer_wildcard].to_s.casecmp?('NONE')
    return items unless or_params[:review_states]
    return items if or_params&.fetch(:only_reviewer_username, false).present?

    states = or_params[:review_states].map { |state| MergeRequestReviewer.states[state] }

    items.with_review_states_or_no_reviewer(states)
  end

  def by_no_review_requested_or_only_user(items)
    return items unless should_apply_reviewer_filter?
    return items if or_params[:review_states]

    items.no_review_requested_or_only_user(or_only_user)
  end

  def by_valid_or_no_reviewers(items)
    return items unless should_apply_reviewer_filter?
    return items unless or_params[:review_states]

    states = or_params[:review_states].map { |state| MergeRequestReviewer.states[state] }

    items.with_valid_or_no_reviewers(states, or_only_user)
  end

  def by_assignee_or_reviewer(items)
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

  def by_closed_at(items)
    closed_after = params[:closed_after]
    closed_before = params[:closed_before]

    return items unless closed_after || closed_before

    items.with_closed_between(closed_after, closed_before)
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

  def or_params
    params[:or]
  end

  def or_only_user
    User.find_by_username(or_params[:only_reviewer_username])
  end
  strong_memoize_attr :or_only_user

  def should_apply_reviewer_filter?
    return false unless or_params&.fetch(:reviewer_wildcard, false).present?
    return false unless or_params&.fetch(:only_reviewer_username, false).present?
    return false unless or_params[:reviewer_wildcard].to_s.casecmp?('NONE')
    return false unless or_only_user

    true
  end
end

MergeRequestsFinder.prepend_mod_with('MergeRequestsFinder')

# frozen_string_literal: true

# IssuableFinder
#
# Used to filter Issues and MergeRequests collections by set of params
#
# Arguments:
#   klass - actual class like Issue or MergeRequest
#   current_user - which user use
#   params:
#     scope: 'created_by_me' or 'assigned_to_me' or 'all'
#     state: 'opened' or 'closed' or 'locked' or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_title: string
#     release_tag: string
#     author_id: integer
#     author_username: string
#     assignee_id: integer or 'None' or 'Any'
#     assignee_username: string
#     search: string
#     in: 'title', 'description', or a string joining them with comma
#     label_name: string
#     sort: string
#     non_archived: boolean
#     iids: integer[]
#     my_reaction_emoji: string
#     created_after: datetime
#     created_before: datetime
#     updated_after: datetime
#     updated_before: datetime
#     attempt_group_search_optimizations: boolean
#     attempt_project_search_optimizations: boolean
#
class IssuableFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include CreatedAtFilter
  include Gitlab::Utils::StrongMemoize

  requires_cross_project_access unless: -> { params.project? }

  NEGATABLE_PARAMS_HELPER_KEYS = %i[include_subgroups in].freeze

  attr_accessor :current_user, :params

  delegate(*%i[assignee milestones], to: :params)

  class << self
    def scalar_params
      @scalar_params ||= %i[
      assignee_id
      assignee_username
      author_id
      author_username
      label_name
      milestone_title
      release_tag
      my_reaction_emoji
      search
      in
    ]
    end

    def array_params
      @array_params ||= { label_name: [], assignee_username: [] }
    end

    # This should not be used in controller strong params!
    def negatable_scalar_params
      @negatable_scalar_params ||= scalar_params + %i[project_id group_id]
    end

    # This should not be used in controller strong params!
    def negatable_array_params
      @negatable_array_params ||= array_params.keys.append(:iids)
    end

    # This should not be used in controller strong params!
    def negatable_params
      @negatable_params ||= negatable_scalar_params + negatable_array_params
    end

    def valid_params
      @valid_params ||= scalar_params + [array_params.merge(not: {})]
    end
  end

  def params_class
    IssuableFinder::Params
  end

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params_class.new(params, current_user, klass)
  end

  def execute
    items = init_collection
    items = filter_items(items)

    # Let's see if we have to negate anything
    items = by_negation(items)

    # This has to be last as we use a CTE as an optimization fence
    # for counts by passing the force_cte param and enabling the
    # attempt_group_search_optimizations feature flag
    # https://www.postgresql.org/docs/current/static/queries-with.html
    items = by_search(items)

    items = sort(items)

    items
  end

  def filter_items(items)
    items = by_project(items)
    items = by_group(items)
    items = by_scope(items)
    items = by_created_at(items)
    items = by_updated_at(items)
    items = by_closed_at(items)
    items = by_state(items)
    items = by_group(items)
    items = by_assignee(items)
    items = by_author(items)
    items = by_non_archived(items)
    items = by_iids(items)
    items = by_milestone(items)
    items = by_release(items)
    items = by_label(items)
    by_my_reaction_emoji(items)
  end

  def row_count
    Gitlab::IssuablesCountForState.new(self).for_state_or_opened(params[:state])
  end

  # We often get counts for each state by running a query per state, and
  # counting those results. This is typically slower than running one query
  # (even if that query is slower than any of the individual state queries) and
  # grouping and counting within that query.
  #
  # rubocop: disable CodeReuse/ActiveRecord
  def count_by_state
    count_params = params.merge(state: nil, sort: nil, force_cte: true)
    finder = self.class.new(current_user, count_params)

    counts = Hash.new(0)

    # Searching by label includes a GROUP BY in the query, but ours will be last
    # because it is added last. Searching by multiple labels also includes a row
    # per issuable, so we have to count those in Ruby - which is bad, but still
    # better than performing multiple queries.
    #
    # This does not apply when we are using a CTE for the search, as the labels
    # GROUP BY is inside the subquery in that case, so we set labels_count to 1.
    #
    # Groups and projects have separate feature flags to suggest the use
    # of a CTE. The CTE will not be used if the sort doesn't support it,
    # but will always be used for the counts here as we ignore sorting
    # anyway.
    labels_count = params.label_names.any? ? params.label_names.count : 1
    labels_count = 1 if use_cte_for_search?

    finder.execute.reorder(nil).group(:state_id).count.each do |key, value|
      counts[count_key(key)] += value / labels_count
    end

    counts[:all] = counts.values.sum

    counts.with_indifferent_access
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def search
    params[:search].presence
  end

  def use_cte_for_search?
    strong_memoize(:use_cte_for_search) do
      next false unless search
      # Only simple unsorted & simple sorts can use CTE
      next false if params[:sort].present? && !params[:sort].in?(klass.simple_sorts.keys)

      attempt_group_search_optimizations? || attempt_project_search_optimizations?
    end
  end

  private

  def force_cte?
    !!params[:force_cte]
  end

  def init_collection
    klass.all
  end

  def attempt_group_search_optimizations?
    params[:attempt_group_search_optimizations] &&
      Feature.enabled?(:attempt_group_search_optimizations, default_enabled: true)
  end

  def attempt_project_search_optimizations?
    params[:attempt_project_search_optimizations] &&
      Feature.enabled?(:attempt_project_search_optimizations, default_enabled: true)
  end

  def count_key(value)
    # value may be an array if the finder used in `count_by_state` added an
    # additional `group by`. Anyway we are sure that state will be always the
    # last item because it's added as the last one to the query.
    value = Array(value).last
    klass.available_states.key(value)
  end

  # Negates all params found in `negatable_params`
  # rubocop: disable CodeReuse/ActiveRecord
  def by_negation(items)
    not_params = params[:not].dup
    # API endpoints send in `nil` values so we test if there are any non-nil
    return items unless not_params.present? && not_params.values.any?

    not_params.keep_if { |_k, v| v.present? }.each do |(key, value)|
      # These aren't negatable params themselves, but rather help other searches, so we skip them.
      # They will be added into all the NOT searches.
      next if NEGATABLE_PARAMS_HELPER_KEYS.include?(key.to_sym)
      next unless self.class.negatable_params.include?(key.to_sym)

      # These are "helper" params that are required inside the NOT to get the right results. They usually come in
      # at the top-level params, but if they do come in inside the `:not` params, they should take precedence.
      not_helpers = params.slice(*NEGATABLE_PARAMS_HELPER_KEYS).merge(params[:not].slice(*NEGATABLE_PARAMS_HELPER_KEYS))
      not_param = { key => value }.with_indifferent_access.merge(not_helpers).merge(not_query: true)

      items_to_negate = self.class.new(current_user, not_param).execute

      items = items.where.not(id: items_to_negate)
    end

    items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_scope(items)
    return items.none if params.current_user_related? && !current_user

    case params[:scope]
    when 'created_by_me', 'authored'
      items.where(author_id: current_user.id)
    when 'assigned_to_me'
      items.assigned_to(current_user)
    else
      items
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_updated_at(items)
    items = items.updated_after(params[:updated_after]) if params[:updated_after].present?
    items = items.updated_before(params[:updated_before]) if params[:updated_before].present?

    items
  end

  def by_closed_at(items)
    items = items.closed_after(params[:closed_after]) if params[:closed_after].present?
    items = items.closed_before(params[:closed_before]) if params[:closed_before].present?

    items
  end

  def by_state(items)
    case params[:state].to_s
    when 'closed'
      items.closed
    when 'merged'
      items.respond_to?(:merged) ? items.merged : items.closed
    when 'opened'
      items.opened
    when 'locked'
      items.with_state(:locked)
    else
      items
    end
  end

  def by_group(items)
    # Selection by group is already covered by `by_project` and `projects`
    items
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_project(items)
    if params.project?
      items.of_projects(params.projects).references_project
    elsif params.projects
      items.merge(params.projects.reorder(nil)).join_project
    else
      items.none
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_search(items)
    return items unless search
    return items if items.is_a?(ActiveRecord::NullRelation)

    if use_cte_for_search?
      cte = Gitlab::SQL::RecursiveCTE.new(klass.table_name)
      cte << items

      items = klass.with(cte.to_arel).from(klass.table_name)
    end

    items.full_search(search, matched_columns: params[:in], use_minimum_char_limit: !use_cte_for_search?)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_iids(items)
    params[:iids].present? ? items.where(iid: params[:iids]) : items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def sort(items)
    # Ensure we always have an explicit sort order (instead of inheriting
    # multiple orders when combining ActiveRecord::Relation objects).
    params[:sort] ? items.sort_by_attribute(params[:sort], excluded_labels: params.label_names) : items.reorder(id: :desc)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_author(items)
    if params.author
      items.where(author_id: params.author.id)
    elsif params.no_author?
      items.where(author_id: nil)
    elsif params.author_id? || params.author_username? # author not found
      items.none
    else
      items
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_assignee(items)
    return items.assigned_to(params.assignees) if not_query? && params.assignees.any?

    if params.filter_by_no_assignee?
      items.unassigned
    elsif params.filter_by_any_assignee?
      items.assigned
    elsif params.assignee
      items.assigned_to(params.assignee)
    elsif params.assignee_id? || params.assignee_username? # assignee not found
      items.none
    else
      items
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_milestone(items)
    return items unless params.milestones?

    if params.filter_by_no_milestone?
      items.left_joins_milestones.where(milestone_id: [-1, nil])
    elsif params.filter_by_any_milestone?
      items.any_milestone
    elsif params.filter_by_upcoming_milestone?
      upcoming_ids = Milestone.upcoming_ids(params.projects, params.related_groups)
      items.left_joins_milestones.where(milestone_id: upcoming_ids)
    elsif params.filter_by_started_milestone?
      items.left_joins_milestones.merge(Milestone.started)
    else
      items.with_milestone(params[:milestone_title])
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_release(items)
    return items unless params.releases?

    if params.filter_by_no_release?
      items.without_release
    elsif params.filter_by_any_release?
      items.any_release
    else
      items.with_release(params[:release_tag], params[:project_id])
    end
  end

  def by_label(items)
    return items unless params.labels?

    if params.filter_by_no_label?
      items.without_label
    elsif params.filter_by_any_label?
      items.any_label
    else
      items.with_label(params.label_names, params[:sort], not_query: not_query?)
    end
  end

  def by_my_reaction_emoji(items)
    return items unless params[:my_reaction_emoji] && current_user

    if params.filter_by_no_reaction?
      items.not_awarded(current_user)
    elsif params.filter_by_any_reaction?
      items.awarded(current_user)
    else
      items.awarded(current_user, params[:my_reaction_emoji])
    end
  end

  def by_non_archived(items)
    params[:non_archived].present? ? items.non_archived : items
  end

  def not_query?
    !!params[:not_query]
  end
end

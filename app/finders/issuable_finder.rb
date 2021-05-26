# frozen_string_literal: true

# IssuableFinder
#
# Used to filter Issues and MergeRequests collections by set of params
#
# Note: This class is NOT meant to be instantiated. Instead you should
#       look at IssuesFinder or EpicsFinder, which inherit from this.
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
  prepend OptimizedIssuableLabelFilter

  requires_cross_project_access unless: -> { params.project? }

  NEGATABLE_PARAMS_HELPER_KEYS = %i[project_id scope status include_subgroups].freeze

  attr_accessor :current_user, :params
  attr_reader :original_params
  attr_writer :parent

  delegate(*%i[milestones], to: :params)

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
      @negatable_scalar_params ||= scalar_params - %i[search in]
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
      @valid_params ||= scalar_params + [array_params.merge(or: {}, not: {})]
    end
  end

  def params_class
    IssuableFinder::Params
  end

  def klass
    raise NotImplementedError
  end

  def initialize(current_user, params = {})
    @current_user = current_user
    @original_params = params
    @params = params_class.new(params, current_user, klass)
  end

  def execute
    items = init_collection
    items = filter_items(items)

    # Let's see if we have to negate anything
    items = filter_negated_items(items) if should_filter_negated_args?

    # This has to be last as we use a CTE as an optimization fence
    # for counts by passing the force_cte param and passing the
    # attempt_group_search_optimizations param
    # https://www.postgresql.org/docs/current/static/queries-with.html
    items = by_search(items)

    sort(items)
  end

  def filter_items(items)
    # Selection by group is already covered by `by_project` and `projects` for project-based issuables
    # Group-based issuables have their own group filter methods
    items = by_project(items)
    items = by_scope(items)
    items = by_created_at(items)
    items = by_updated_at(items)
    items = by_closed_at(items)
    items = by_state(items)
    items = by_assignee(items)
    items = by_author(items)
    items = by_non_archived(items)
    items = by_iids(items)
    items = by_milestone(items)
    items = by_release(items)
    items = by_label(items)
    by_my_reaction_emoji(items)
  end

  def should_filter_negated_args?
    # API endpoints send in `nil` values so we test if there are any non-nil
    not_params.present? && not_params.values.any?
  end

  # Negates all params found in `negatable_params`
  def filter_negated_items(items)
    items = by_negated_label(items)
    items = by_negated_milestone(items)
    items = by_negated_release(items)
    items = by_negated_my_reaction_emoji(items)
    by_negated_iids(items)
  end

  def row_count
    Gitlab::IssuablesCountForState
      .new(self, nil, fast_fail: true)
      .for_state_or_opened(params[:state])
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

  def parent_param=(obj)
    @parent = obj
    params[parent_param] = parent if parent
  end

  def parent_param
    case parent
    when Project
      :project_id
    when Group
      :group_id
    else
      raise "Unexpected parent: #{parent.class}"
    end
  end

  private

  attr_reader :parent

  def not_params
    strong_memoize(:not_params) do
      params_class.new(params[:not].dup, current_user, klass).tap do |not_params|
        next unless not_params.present?

        # These are "helper" params that modify the results, like :in and :search. They usually come in at the top-level
        # params, but if they do come in inside the `:not` params, the inner ones should take precedence.
        not_helpers = params.slice(*NEGATABLE_PARAMS_HELPER_KEYS).merge(params[:not].to_h.slice(*NEGATABLE_PARAMS_HELPER_KEYS))
        not_helpers.each do |key, value|
          not_params[key] = value unless not_params[key].present?
        end
      end
    end
  end

  def force_cte?
    !!params[:force_cte]
  end

  def init_collection
    klass.all
  end

  def attempt_group_search_optimizations?
    params[:attempt_group_search_optimizations]
  end

  def attempt_project_search_optimizations?
    params[:attempt_project_search_optimizations]
  end

  def count_key(value)
    # value may be an array if the finder used in `count_by_state` added an
    # additional `group by`. Anyway we are sure that state will be always the
    # last item because it's added as the last one to the query.
    value = Array(value).last
    klass.available_states.key(value)
  end

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
      cte = Gitlab::SQL::CTE.new(klass.table_name, items)

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
  def by_negated_iids(items)
    not_params[:iids].present? ? items.where.not(iid: not_params[:iids]) : items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def sort(items)
    # Ensure we always have an explicit sort order (instead of inheriting
    # multiple orders when combining ActiveRecord::Relation objects).
    params[:sort] ? items.sort_by_attribute(params[:sort], excluded_labels: params.label_names) : items.reorder(id: :desc)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_author(items)
    Issuables::AuthorFilter.new(
      params: original_params,
      or_filters_enabled: or_filters_enabled?
    ).filter(items)
  end

  def by_assignee(items)
    assignee_filter.filter(items)
  end

  def assignee_filter
    strong_memoize(:assignee_filter) do
      Issuables::AssigneeFilter.new(
        params: original_params,
        or_filters_enabled: or_filters_enabled?
      )
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

  # rubocop: disable CodeReuse/ActiveRecord
  def by_negated_milestone(items)
    return items unless not_params.milestones?

    if not_params.filter_by_upcoming_milestone?
      items.joins(:milestone).merge(Milestone.not_upcoming)
    elsif not_params.filter_by_started_milestone?
      items.joins(:milestone).merge(Milestone.not_started)
    else
      items.without_particular_milestone(not_params[:milestone_title])
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_release(items)
    return items unless params.releases?
    return items if params.group? # don't allow release filtering at group level

    if params.filter_by_no_release?
      items.without_release
    elsif params.filter_by_any_release?
      items.any_release
    else
      items.with_release(params[:release_tag], params[:project_id])
    end
  end

  def by_negated_release(items)
    return items unless not_params.releases?

    items.without_particular_release(not_params[:release_tag], not_params[:project_id])
  end

  def by_label(items)
    return items unless params.labels?

    if params.filter_by_no_label?
      items.without_label
    elsif params.filter_by_any_label?
      items.any_label(params[:sort])
    else
      items.with_label(params.label_names, params[:sort])
    end
  end

  def by_negated_label(items)
    return items unless not_params.labels?

    items.without_particular_labels(not_params.label_names)
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

  def by_negated_my_reaction_emoji(items)
    return items unless not_params[:my_reaction_emoji] && current_user

    items.not_awarded(current_user, not_params[:my_reaction_emoji])
  end

  def by_non_archived(items)
    params[:non_archived].present? ? items.non_archived : items
  end

  def or_filters_enabled?
    strong_memoize(:or_filters_enabled) do
      Feature.enabled?(:or_issuable_queries, feature_flag_scope, default_enabled: :yaml)
    end
  end

  def feature_flag_scope
    params.group || params.project
  end
end

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
#     milestone_title: string (cannot be simultaneously used with milestone_wildcard_id)
#     milestone_wildcard_id: 'none', 'any', 'upcoming', 'started' (cannot be simultaneously used with milestone_title)
#     release_tag: string
#     author_id: integer
#     author_username: string
#     assignee_id: integer or 'None' or 'Any'
#     closed_by_id: integer
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
#     crm_contact_id: integer
#     crm_organization_id: integer
#
class IssuableFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include CreatedAtFilter
  include Gitlab::Utils::StrongMemoize
  include UpdatedAtFilter

  requires_cross_project_access unless: -> { params.project? }

  FULL_TEXT_SEARCH_TERM_PATTERN = '[\u0000-\u02FF\u1E00-\u1EFF\u2070-\u218F]*'
  FULL_TEXT_SEARCH_TERM_REGEX = /\A#{FULL_TEXT_SEARCH_TERM_PATTERN}\z/
  NEGATABLE_PARAMS_HELPER_KEYS = %i[project_id scope status include_subgroups].freeze

  attr_accessor :current_user, :params
  attr_reader :original_params
  attr_writer :parent

  delegate(*%i[milestones], to: :params)

  class << self
    def scalar_params
      @scalar_params ||= %i[
        assignee_id
        closed_by_id
        assignee_username
        author_id
        author_username
        crm_contact_id
        crm_organization_id
        in
        label_name
        milestone_title
        release_tag
        my_reaction_emoji
        search
        subscribed
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
    items = by_parent(items)
    items = by_scope(items)
    items = by_created_at(items)
    items = by_updated_at(items)
    items = by_closed_at(items)
    items = by_state(items)
    items = by_assignee(items)
    items = by_closed_by(items)
    items = by_author(items)
    items = by_non_archived(items)
    items = by_iids(items)
    items = by_milestone(items)
    items = by_release(items)
    items = by_label(items)
    items = by_my_reaction_emoji(items)
    items = by_crm_contact(items)
    items = by_subscribed(items)
    by_crm_organization(items)
  end

  def should_filter_negated_args?
    # API endpoints send in `nil` values so we test if there are any non-nil
    not_params.present? && not_params.values.any?
  end

  # Negates all params found in `negatable_params`
  def filter_negated_items(items)
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

    state_counts = finder
      .execute
      .reorder(nil)
      .group(:state_id)
      .count

    counts = Hash.new(0)

    state_counts.each do |key, value|
      counts[count_key(key)] += value
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
      next false unless default_or_simple_sort?

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
        not_helpers = params.slice(*NEGATABLE_PARAMS_HELPER_KEYS)
                            .merge(params[:not].to_h.slice(*NEGATABLE_PARAMS_HELPER_KEYS))
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
    return klass.all if params.user_can_see_all_issuables?

    # Only admins and auditors can see hidden issuables, for other users we filter out hidden issuables
    klass.without_hidden
  end

  def default_or_simple_sort?
    params[:sort].blank? || params[:sort].to_s.in?(klass.simple_sorts.keys)
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
  def by_parent(items)
    # When finding issues for multiple projects it's more efficient
    # to use a JOIN instead of running a sub-query
    # See https://gitlab.com/gitlab-org/gitlab/-/commit/8591cc02be6b12ed60f763a5e0147f2cbbca99e1
    if params.projects.is_a?(ActiveRecord::Relation)
      items.merge(params.projects.reorder(nil)).join_project
    elsif params.projects
      items.of_projects(params.projects).references_project
    else
      items.none
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_search(items)
    return items unless search
    return items if items.null_relation?

    return filter_by_full_text_search(items) if use_full_text_search?

    if use_cte_for_search?
      cte = Gitlab::SQL::CTE.new(klass.table_name, items)

      items = klass.with(cte.to_arel).from(klass.table_name)
    end

    items.full_search(search, matched_columns: params[:in], use_minimum_char_limit: !use_cte_for_search?)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def use_full_text_search?
    klass.try(:pg_full_text_searchable_columns).present? &&
      params[:search] =~ FULL_TEXT_SEARCH_TERM_REGEX
  end

  def filter_by_full_text_search(items)
    items.pg_full_text_search(search, matched_columns: params[:in].to_s.split(','))
  end

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
    if params[:sort]
      items.sort_by_attribute(
        params[:sort],
        excluded_labels: label_filter.label_names_excluded_from_priority_sort
      )
    else
      items.reorder(id: :desc)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_author(items)
    Issuables::AuthorFilter.new(
      params: original_params
    ).filter(items)
  end

  def by_assignee(items)
    assignee_filter.filter(items)
  end

  def assignee_filter
    strong_memoize(:assignee_filter) do
      Issuables::AssigneeFilter.new(
        params: original_params
      )
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_closed_by(items)
    return items if params[:closed_by_id].blank?

    items.where(closed_by_id: params[:closed_by_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_label(items)
    label_filter.filter(items)
  end

  def label_filter
    strong_memoize(:label_filter) do
      Issuables::LabelFilter.new(
        params: original_params,
        project: params.project,
        group: params.group
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
      items.without_particular_milestones(not_params[:milestone_title])
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

  def by_my_reaction_emoji(items)
    return items unless params[:my_reaction_emoji] && current_user

    if params.filter_by_no_reaction?
      items.not_awarded(current_user)
    elsif params.filter_by_any_reaction?
      items.awarded(current_user)
    else
      items.awarded(current_user, name: params[:my_reaction_emoji])
    end
  end

  def by_negated_my_reaction_emoji(items)
    return items unless not_params[:my_reaction_emoji] && current_user

    items.not_awarded(current_user, name: not_params[:my_reaction_emoji])
  end

  def by_non_archived(items)
    params[:non_archived].present? ? items.non_archived : items
  end

  def by_crm_contact(items)
    return items unless can_filter_by_crm_contact?

    Issuables::CrmContactFilter.new(params: original_params).filter(items)
  end

  def by_crm_organization(items)
    return items unless can_filter_by_crm_organization?

    Issuables::CrmOrganizationFilter.new(params: original_params).filter(items)
  end

  def by_subscribed(items)
    return items unless current_user

    case params[:subscribed]
    when :explicitly_subscribed
      items.explicitly_subscribed(current_user)
    when :explicitly_unsubscribed
      items.explicitly_unsubscribed(current_user)
    else
      items
    end
  end

  def can_filter_by_crm_contact?
    current_user&.can?(:read_crm_contact, root_group)
  end

  def can_filter_by_crm_organization?
    current_user&.can?(:read_crm_organization, root_group)
  end

  def root_group
    strong_memoize(:root_group) do
      base_group = params.group || params.project&.group

      base_group&.root_ancestor
    end
  end
end

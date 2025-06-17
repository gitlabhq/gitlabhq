# frozen_string_literal: true

# TodosFinder
#
# Used to filter Todos by set of params
#
# Arguments:
#   users: which user or users, provided as a list, to use.
#   action_id: integer
#   author_id: integer
#   project_id; integer
#   target_id; integer
#   state: 'pending' (default) or 'done'
#   is_snoozed: boolean
#   type: 'Issue' or 'MergeRequest' or ['Issue', 'MergeRequest']
#

class TodosFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include Gitlab::Utils::StrongMemoize
  include SafeFormatHelper

  requires_cross_project_access unless: -> { project? }

  NONE = '0'

  TODO_TYPES = Set.new(
    %w[Commit Issue WorkItem MergeRequest DesignManagement::Design AlertManagement::Alert Namespace Project Key
      WikiPage::Meta]
  ).freeze

  attr_accessor :params

  class << self
    def todo_types
      TODO_TYPES
    end
  end

  def initialize(users:, **params)
    @users = users
    @params = params
    self.should_skip_cross_project_check = true if skip_cross_project_check?
  end

  def execute
    return Todo.none if users.blank?
    raise ArgumentError, invalid_type_message unless valid_types?

    items = Todo.for_user(users)
    items = without_hidden(items)
    items = by_action_id(items)
    items = by_action(items)
    items = by_author(items)
    items = by_state(items)
    items = by_snoozed_status(items)
    items = by_target_id(items)
    items = by_types(items)
    items = by_group(items)
    # Filtering by project HAS TO be the last because we use
    # the project IDs yielded by the todos query thus far
    items = by_project(items)

    sort(items)
  end

  private

  attr_reader :users

  def skip_cross_project_check?
    users.blank? || users_list.size > 1
  end

  def current_user
    # This is needed by the FinderMethods module and by the FinderWithCrossProjectAccess module
    # when they do permission checks for a user.
    # When there are multiple users, we should find another way to check permissions if needed
    # outside this layer.
    raise NoMethodError, 'This method is not available when executing with multiple users' if skip_cross_project_check?

    users_list.first
  end

  def users_list
    Array.wrap(users)
  end

  def action_id?
    action_id.present? && Todo.action_names.key?(action_id.to_i)
  end

  def action_id
    params[:action_id]
  end

  def action_array_provided?
    params[:action].is_a?(Array)
  end

  def map_actions_to_ids
    params[:action].map { |item| Todo.action_names.key(item.to_sym) }
  end

  def to_action_id
    if action_array_provided?
      map_actions_to_ids
    else
      Todo.action_names.key(action.to_sym)
    end
  end

  def action?
    action.present? && to_action_id
  end

  def action
    params[:action]
  end

  def snoozed?
    params[:is_snoozed]
  end

  def author?
    params[:author_id].present?
  end

  def author
    strong_memoize(:author) do
      User.find(params[:author_id]) if author? && params[:author_id] != NONE
    end
  end

  def project?
    params[:project_id].present?
  end

  def group?
    params[:group_id].present?
  end

  def group
    strong_memoize(:group) do
      Group.find(params[:group_id])
    end
  end

  def types
    @types ||= Array(params[:type]).reject(&:blank?)
  end

  def valid_types?
    types.all? { |type| self.class.todo_types.include?(type) }
  end

  def invalid_type_message
    safe_format(_("Unsupported todo type passed. Supported todo types are: %{todo_types}"),
      todo_types: self.class.todo_types.to_a.join(', '))
  end

  def sort(items)
    sort_by = case params[:sort]
              # If no sort order is provided, we default to sorting by ID to bypass the custom sort
              # by snoozed_until and created_at which could break some SQL queries.
              when nil
                :id_desc
              when :created_desc
                use_snooze_custom_sort? ? :snoozed_and_creation_dates_desc : :id_desc
              when :created_asc
                use_snooze_custom_sort? ? :snoozed_and_creation_dates_asc : :id_asc
              else
                params[:sort]
              end

    items.sort_by_attribute(sort_by)
  end

  # We only need to surface snoozed to-dos when querying pending items. The special sort order is
  # unnecessary in the `Done` and `All` tabs where we can simply sort by ID (= creation date).
  def use_snooze_custom_sort?
    filter_pending_only?
  end

  def by_action(items)
    if action?
      items.for_action(to_action_id)
    else
      items
    end
  end

  def action_id_array_provided?
    params[:action_id].is_a?(Array) && params[:action_id].any?
  end

  def by_action_ids(items)
    items.for_action(action_id)
  end

  def by_action_id(items)
    return by_action_ids(items) if action_id_array_provided?

    if action_id?
      by_action_ids(items)
    else
      items
    end
  end

  def by_author(items)
    if author?
      items.for_author(author)
    else
      items
    end
  end

  def by_project(items)
    if project?
      items.for_undeleted_projects.for_project(params[:project_id])
    else
      items
    end
  end

  def by_group(items)
    return items unless group?

    items.for_group_ids_and_descendants(params[:group_id])
  end

  def by_state(items)
    return items.pending if filter_pending_only?
    return items.done if filter_done_only?

    items
  end

  def by_snoozed_status(items)
    return items.snoozed if snoozed?
    return items.not_snoozed if filter_pending_only?

    items
  end

  def by_target_id(items)
    return items if params[:target_id].blank?

    items.for_target(params[:target_id])
  end

  def by_types(items)
    if types.any?
      items.for_type(types)
    else
      items
    end
  end

  def without_hidden(items)
    return items.pending_without_hidden if filter_pending_only?
    return items if filter_done_only? || filter_all?

    items.all_without_hidden
  end

  def filter_all?
    Array.wrap(params[:state]).map(&:to_sym) == [:all]
  end

  def filter_pending_only?
    params[:state].blank? || Array.wrap(params[:state]).map(&:to_sym) == [:pending]
  end

  def filter_done_only?
    Array.wrap(params[:state]).map(&:to_sym) == [:done]
  end
end

TodosFinder.prepend_mod_with('TodosFinder')

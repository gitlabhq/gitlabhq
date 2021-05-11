# frozen_string_literal: true

# TodosFinder
#
# Used to filter Todos by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     action_id: integer
#     author_id: integer
#     project_id; integer
#     target_id; integer
#     state: 'pending' (default) or 'done'
#     type: 'Issue' or 'MergeRequest' or ['Issue', 'MergeRequest']
#

class TodosFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include Gitlab::Utils::StrongMemoize

  requires_cross_project_access unless: -> { project? }

  NONE = '0'

  TODO_TYPES = Set.new(%w(Issue MergeRequest DesignManagement::Design AlertManagement::Alert)).freeze

  attr_accessor :current_user, :params

  class << self
    def todo_types
      TODO_TYPES
    end
  end

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    return Todo.none if current_user.nil?
    raise ArgumentError, invalid_type_message unless valid_types?

    items = current_user.todos
    items = by_action_id(items)
    items = by_action(items)
    items = by_author(items)
    items = by_state(items)
    items = by_target_id(items)
    items = by_types(items)
    items = by_group(items)
    # Filtering by project HAS TO be the last because we use
    # the project IDs yielded by the todos query thus far
    items = by_project(items)

    sort(items)
  end

  # Returns `true` if the current user has any todos for the given target with the optional given state.
  #
  # target - The value of the `target_type` column, such as `Issue`.
  # state - The value of the `state` column, such as `pending` or `done`.
  def any_for_target?(target, state = nil)
    current_user.todos.any_for_target?(target, state)
  end

  private

  def action_id?
    action_id.present? && Todo::ACTION_NAMES.key?(action_id.to_i)
  end

  def action_id
    params[:action_id]
  end

  def action_array_provided?
    params[:action].is_a?(Array)
  end

  def map_actions_to_ids
    params[:action].map { |item| Todo::ACTION_NAMES.key(item.to_sym) }
  end

  def to_action_id
    if action_array_provided?
      map_actions_to_ids
    else
      Todo::ACTION_NAMES.key(action.to_sym)
    end
  end

  def action?
    action.present? && to_action_id
  end

  def action
    params[:action]
  end

  def author?
    params[:author_id].present?
  end

  def author
    strong_memoize(:author) do
      if author? && params[:author_id] != NONE
        User.find(params[:author_id])
      end
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
    _("Unsupported todo type passed. Supported todo types are: %{todo_types}") % { todo_types: self.class.todo_types.to_a.join(', ') }
  end

  def sort(items)
    if params[:sort]
      items.sort_by_attribute(params[:sort])
    else
      items.order_id_desc
    end
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
    return items.pending if params[:state].blank?

    items.with_states(params[:state])
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
end

TodosFinder.prepend_mod_with('TodosFinder')

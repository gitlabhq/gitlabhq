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
#     state: 'pending' (default) or 'done'
#     type: 'Issue' or 'MergeRequest'
#

class TodosFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods
  include Gitlab::Utils::StrongMemoize

  requires_cross_project_access unless: -> { project? }

  NONE = '0'

  TODO_TYPES = Set.new(%w(Issue MergeRequest Epic)).freeze

  attr_accessor :current_user, :params

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    items = current_user.todos
    items = by_action_id(items)
    items = by_action(items)
    items = by_author(items)
    items = by_state(items)
    items = by_type(items)
    items = by_group(items)
    # Filtering by project HAS TO be the last because we use
    # the project IDs yielded by the todos query thus far
    items = by_project(items)

    sort(items)
  end

  # Returns `true` if the current user has any todos for the given target.
  #
  # target - The value of the `target_type` column, such as `Issue`.
  def any_for_target?(target)
    current_user.todos.any_for_target?(target)
  end

  private

  def action_id?
    action_id.present? && Todo::ACTION_NAMES.key?(action_id.to_i)
  end

  def action_id
    params[:action_id]
  end

  def to_action_id
    Todo::ACTION_NAMES.key(action.to_sym)
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

  def project
    strong_memoize(:project) do
      Project.find_without_deleted(params[:project_id]) if project?
    end
  end

  def group
    strong_memoize(:group) do
      Group.find(params[:group_id])
    end
  end

  def type?
    type.present? && TODO_TYPES.include?(type)
  end

  def type
    params[:type]
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

  def by_action_id(items)
    if action_id?
      items.for_action(action_id)
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
      items.for_project(project)
    else
      items
    end
  end

  def by_group(items)
    if group?
      items.for_group_and_descendants(group)
    else
      items
    end
  end

  def by_state(items)
    if params[:state].to_s == 'done'
      items.done
    else
      items.pending
    end
  end

  def by_type(items)
    if type?
      items.for_type(type)
    else
      items
    end
  end
end

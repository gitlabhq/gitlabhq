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

  NONE = '0'.freeze

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
    return @author if defined?(@author)

    @author =
      if author? && params[:author_id] != NONE
        User.find(params[:author_id])
      else
        nil
      end
  end

  def project?
    params[:project_id].present?
  end

  def group?
    params[:group_id].present?
  end

  def project
    return @project if defined?(@project)

    if project?
      @project = Project.find(params[:project_id])

      @project = nil if @project.pending_delete?
    else
      @project = nil
    end

    @project
  end

  def group
    strong_memoize(:group) do
      Group.find(params[:group_id])
    end
  end

  def type?
    type.present? && %w(Issue MergeRequest Epic).include?(type)
  end

  def type
    params[:type]
  end

  def sort(items)
    params[:sort] ? items.sort_by_attribute(params[:sort]) : items.order_id_desc
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_action(items)
    if action?
      items = items.where(action: to_action_id)
    end

    items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_action_id(items)
    if action_id?
      items = items.where(action: action_id)
    end

    items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_author(items)
    if author?
      items = items.where(author_id: author.try(:id))
    end

    items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_project(items)
    if project?
      items = items.where(project: project)
    end

    items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_group(items)
    return items unless group?

    groups = group.self_and_descendants
    project_todos = items.where(project_id: Project.where(group: groups).select(:id))
    group_todos = items.where(group_id: groups.select(:id))

    Todo.from_union([project_todos, group_todos])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_state(items)
    case params[:state].to_s
    when 'done'
      items.done
    else
      items.pending
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_type(items)
    if type?
      items = items.where(target_type: type)
    end

    items
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

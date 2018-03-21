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

  def project
    return @project if defined?(@project)

    if project?
      @project = Project.find(params[:project_id])

      @project = nil if @project.pending_delete?

      unless Ability.allowed?(current_user, :read_project, @project)
        @project = nil
      end
    else
      @project = nil
    end

    @project
  end

  def project_ids(items)
    ids = items.except(:order).select(:project_id)
    if Gitlab::Database.mysql?
      # To make UPDATE work on MySQL, wrap it in a SELECT with an alias
      ids = Todo.except(:order).select('*').from("(#{ids.to_sql}) AS t")
    end

    ids
  end

  def type?
    type.present? && %w(Issue MergeRequest).include?(type)
  end

  def type
    params[:type]
  end

  def sort(items)
    params[:sort] ? items.sort(params[:sort]) : items.order_id_desc
  end

  def by_action(items)
    if action?
      items = items.where(action: to_action_id)
    end

    items
  end

  def by_action_id(items)
    if action_id?
      items = items.where(action: action_id)
    end

    items
  end

  def by_author(items)
    if author?
      items = items.where(author_id: author.try(:id))
    end

    items
  end

  def by_project(items)
    if project?
      items.where(project: project)
    else
      projects = Project.public_or_visible_to_user(current_user)

      items.joins(:project).merge(projects)
    end
  end

  def by_state(items)
    case params[:state].to_s
    when 'done'
      items.done
    else
      items.pending
    end
  end

  def by_type(items)
    if type?
      items = items.where(target_type: type)
    end

    items
  end
end

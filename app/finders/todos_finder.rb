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
#     state: 'pending' or 'done'
#     type: 'Issue' or 'MergeRequest'
#

class TodosFinder
  NONE = '0'

  attr_accessor :current_user, :params

  def initialize(current_user, params)
    @current_user = current_user
    @params = params
  end

  def execute
    items = current_user.todos
    items = by_action_id(items)
    items = by_author(items)
    items = by_project(items)
    items = by_state(items)
    items = by_type(items)

    items
  end

  private

  def action_id?
    action_id.present? && [Todo::ASSIGNED, Todo::MENTIONED].include?(action_id.to_i)
  end

  def action_id
    params[:action_id]
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

      unless Ability.abilities.allowed?(current_user, :read_project, @project)
        @project = nil
      end
    else
      @project = nil
    end

    @project
  end

  def type?
    type.present? && ['Issue', 'MergeRequest'].include?(type)
  end

  def type
    params[:type]
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
      items = items.where(project: project)
    end

    items
  end

  def by_state(items)
    case params[:state]
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

module TodosHelper
  def todos_pending_count
    current_user.todos.pending.count
  end

  def todos_done_count
    current_user.todos.done.count
  end

  def todo_target_link(todo)
    target = todo.target_type.titleize.downcase
    link_to "#{target} #{todo.target.to_reference}", todo_target_path(todo)
  end

  def todo_target_path(todo)
    anchor = dom_id(todo.note) if todo.note.present?

    polymorphic_path([todo.project.namespace.becomes(Namespace),
                      todo.project, todo.target], anchor: anchor)
  end

  def todo_actions_options
    actions = [
      OpenStruct.new(id: '', title: 'Any Action'),
      OpenStruct.new(id: Todo::ASSIGNED, title: 'Assigned'),
      OpenStruct.new(id: Todo::MENTIONED, title: 'Mentioned')
    ]

    options_from_collection_for_select(actions, 'id', 'title', params[:action_id])
  end

  def todo_projects_options
    projects = current_user.authorized_projects.sorted_by_activity.non_archived
    projects = projects.includes(:namespace)

    projects = projects.map do |project|
      OpenStruct.new(id: project.id, title: project.name_with_namespace)
    end

    projects.unshift(OpenStruct.new(id: '', title: 'Any Project'))

    options_from_collection_for_select(projects, 'id', 'title', params[:project_id])
  end

  def todo_types_options
    types = [
      OpenStruct.new(title: 'Any Type', name: ''),
      OpenStruct.new(title: 'Issue', name: 'Issue'),
      OpenStruct.new(title: 'Merge Request', name: 'MergeRequest')
    ]

    options_from_collection_for_select(types, 'name', 'title', params[:type])
  end
end

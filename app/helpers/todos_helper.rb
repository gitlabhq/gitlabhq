module TodosHelper
  def todos_pending_count
    @todos_pending_count ||= current_user.todos_pending_count
  end

  def todos_done_count
    @todos_done_count ||= current_user.todos_done_count
  end

  def todo_action_name(todo)
    case todo.action
    when Todo::ASSIGNED then 'assigned you'
    when Todo::MENTIONED then 'mentioned you on'
    when Todo::BUILD_FAILED then 'The build failed for your'
    when Todo::MARKED then 'added a todo for'
    when Todo::APPROVAL_REQUIRED then 'set you as an approver for'
    end
  end

  def todo_target_link(todo)
    target = todo.target_type.titleize.downcase
    link_to "#{target} #{todo.target_reference}", todo_target_path(todo),
      class: 'has-tooltip',
      title: todo.target.title
  end

  def todo_target_path(todo)
    return unless todo.target.present?

    anchor = dom_id(todo.note) if todo.note.present?

    if todo.for_commit?
      namespace_project_commit_path(todo.project.namespace.becomes(Namespace), todo.project,
                                    todo.target, anchor: anchor)
    else
      path = [todo.project.namespace.becomes(Namespace), todo.project, todo.target]

      path.unshift(:builds) if todo.build_failed?

      polymorphic_path(path, anchor: anchor)
    end
  end

  def todo_target_state_pill(todo)
    return unless show_todo_state?(todo)

    content_tag(:span, nil, class: 'target-status') do
      content_tag(:span, nil, class: "status-box status-box-#{todo.target.state.dasherize}") do
        todo.target.state.capitalize
      end
    end
  end

  def todos_filter_params
    {
      state:      params[:state],
      project_id: params[:project_id],
      author_id:  params[:author_id],
      type:       params[:type],
      action_id:  params[:action_id],
    }
  end

  def todos_filter_path(options = {})
    without = options.delete(:without)

    options = todos_filter_params.merge(options)

    if without.present?
      without.each do |key|
        options.delete(key)
      end
    end

    path = request.path
    path << "?#{options.to_param}"
    path
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

  private

  def show_todo_state?(todo)
    (todo.target.is_a?(MergeRequest) || todo.target.is_a?(Issue)) && ['closed', 'merged'].include?(todo.target.state)
  end
end

module TasksHelper
  def link_to_author(task)
    author = task.author

    if author
      link_to author.name, user_path(author.username)
    else
      task.author_name
    end
  end

  def tasks_pending_count
    current_user.tasks.pending.count
  end

  def tasks_done_count
    current_user.tasks.done.count
  end

  def task_action_name(task)
    target =  task.target_type.titleize.downcase

    [task.action_name, target].join(" ")
  end

  def task_note_link_html(task)
    link_to task_note_target_path(task) do
      "##{task.target_iid}"
    end
  end

  def task_note_target_path(task)
    polymorphic_path([task.project.namespace.becomes(Namespace),
                      task.project, task.target], anchor: dom_id(task.note))
  end

  def task_note(text, options = {})
    text = first_line_in_markdown(text, 150, options)
    sanitize(text, tags: %w(a img b pre code p span))
  end

  def task_actions_options
    actions = [
      OpenStruct.new(id: '', title: 'Any Action'),
      OpenStruct.new(id: Task::ASSIGNED, title: 'Assigned'),
      OpenStruct.new(id: Task::MENTIONED, title: 'Mentioned')
    ]

    options_from_collection_for_select(actions, 'id', 'title', params[:action_id])
  end

  def task_projects_options
    projects = current_user.authorized_projects.sorted_by_activity.non_archived
    projects = projects.includes(:namespace)

    projects = projects.map do |project|
      OpenStruct.new(id: project.id, title: project.name_with_namespace)
    end

    projects.unshift(OpenStruct.new(id: '', title: 'Any Project'))

    options_from_collection_for_select(projects, 'id', 'title', params[:project_id])
  end

  def task_types_options
    types = [
      OpenStruct.new(title: 'Any Type', name: ''),
      OpenStruct.new(title: 'Issue', name: 'Issue'),
      OpenStruct.new(title: 'Merge Request', name: 'MergeRequest')
    ]

    options_from_collection_for_select(types, 'name', 'title', params[:type])
  end
end

module EpicsHelper
  def epic_show_app_data(epic, opts)
    author = epic.author
    group = epic.group
    todo = issuable_todo(epic)

    epic_meta = {
      epic_id: epic.id,
      created: epic.created_at,
      author: {
        name: author.name,
        url: user_path(author),
        username: "@#{author.username}",
        src: opts[:author_icon]
      },
      todo_exists: todo.present?,
      todo_path: group_todos_path(group),
      start_date: epic.start_date,
      end_date: epic.end_date
    }

    epic_meta[:todo_delete_path] = dashboard_todo_path(todo) if todo.present?

    participants = UserSerializer.new.represent(epic.participants)
    initial = opts[:initial].merge(labels: epic.labels,
                                   participants: participants,
                                   subscribed: epic.subscribed?(current_user))

    {
      initial: initial.to_json,
      meta: epic_meta.to_json,
      namespace: group.path,
      labels_path: group_labels_path(group, format: :json, only_group_labels: true, include_ancestor_groups: true),
      toggle_subscription_path: toggle_subscription_group_epic_path(group, epic),
      labels_web_url: group_labels_path(group),
      epics_web_url: group_epics_path(group)
    }
  end

  def epic_endpoint_query_params(opts)
    opts[:data] ||= {}
    opts[:data][:endpoint_query_params] = {
        only_group_labels: true,
        include_ancestor_groups: true,
        include_descendant_groups: true
    }.to_json

    opts
  end
end

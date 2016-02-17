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
end

module TasksHelper
  def link_to_author(task)
    author = task.author

    if author
      link_to author.name, user_path(author.username)
    else
      task.author_name
    end
  end

  def task_action_name(task)
    target =  task.target_type.titleize.downcase

    [task.action_name, target].join(" ")
  end
end

# TaskService class
#
# Used for creating tasks on task queue after certain user action
#
# Ex.
#   TaskService.new.new_issue(issue, current_user)
#
class TaskService
  # When create an issue we should:
  #
  #  * create a task for assignee if issue is assigned
  #  * create a task for each mentioned user on issue
  #
  def new_issue(issue, current_user)
    new_issuable(issue, current_user)
  end

  # When update an issue we should:
  #
  #  * mark all pending tasks related to the issue for the current user as done
  #
  def update_issue(issue, current_user)
    create_mention_tasks(issue.project, issue, current_user)
  end

  # When close an issue we should:
  #
  #  * mark all pending tasks related to the target for the current user as done
  #
  def close_issue(issue, current_user)
    mark_pending_tasks_as_done(issue, current_user)
  end

  # When we reassign an issue we should:
  #
  #  * create a pending task for new assignee if issue is assigned
  #
  def reassigned_issue(issue, current_user)
    create_assignment_task(issue, current_user)
  end

  # When create a merge request we should:
  #
  #  * creates a pending task for assignee if merge request is assigned
  #  * create a task for each mentioned user on merge request
  #
  def new_merge_request(merge_request, current_user)
    new_issuable(merge_request, current_user)
  end

  # When update a merge request we should:
  #
  #  * create a task for each mentioned user on merge request
  #
  def update_merge_request(merge_request, current_user)
    create_mention_tasks(merge_request.project, merge_request, current_user)
  end

  # When close a merge request we should:
  #
  #  * mark all pending tasks related to the target for the current user as done
  #
  def close_merge_request(merge_request, current_user)
    mark_pending_tasks_as_done(merge_request, current_user)
  end

  # When we reassign a merge request we should:
  #
  #  * creates a pending task for new assignee if merge request is assigned
  #
  def reassigned_merge_request(merge_request, current_user)
    create_assignment_task(merge_request, current_user)
  end

  # When merge a merge request we should:
  #
  #  * mark all pending tasks related to the target for the current user as done
  #
  def merge_merge_request(merge_request, current_user)
    mark_pending_tasks_as_done(merge_request, current_user)
  end

  # When create a note we should:
  #
  #  * mark all pending tasks related to the noteable for the note author as done
  #  * create a task for each mentioned user on note
  #
  def new_note(note, current_user)
    handle_note(note, current_user)
  end

  # When update a note we should:
  #
  #  * mark all pending tasks related to the noteable for the current user as done
  #  * create a task for each new user mentioned on note
  #
  def update_note(note, current_user)
    handle_note(note, current_user)
  end

  # When marking pending tasks as done we should:
  #
  #  * mark all pending tasks related to the target for the current user as done
  #
  def mark_pending_tasks_as_done(target, user)
    pending_tasks(user, target.project, target).update_all(state: :done)
  end

  private

  def create_tasks(project, target, author, users, action, note = nil)
    Array(users).each do |user|
      next if pending_tasks(user, project, target).exists?

      Task.create(
        project: project,
        user_id: user.id,
        author_id: author.id,
        target_id: target.id,
        target_type: target.class.name,
        action: action,
        note: note
      )
    end
  end

  def new_issuable(issuable, author)
    create_assignment_task(issuable, author)
    create_mention_tasks(issuable.project, issuable, author)
  end

  def handle_note(note, author)
    # Skip system notes, like status changes and cross-references
    return if note.system

    project = note.project
    target  = note.noteable

    mark_pending_tasks_as_done(target, author)
    create_mention_tasks(project, target, author, note)
  end

  def create_assignment_task(issuable, author)
    if issuable.assignee && issuable.assignee != author
      create_tasks(issuable.project, issuable, author, issuable.assignee, Task::ASSIGNED)
    end
  end

  def create_mention_tasks(project, issuable, author, note = nil)
    mentioned_users = filter_mentioned_users(project, note || issuable, author)
    create_tasks(project, issuable, author, mentioned_users, Task::MENTIONED, note)
  end

  def filter_mentioned_users(project, target, author)
    mentioned_users = target.mentioned_users.select do |user|
      user.can?(:read_project, project)
    end

    mentioned_users.delete(author)
    mentioned_users.uniq
  end

  def pending_tasks(user, project, target)
    user.tasks.pending.where(
      project_id: project.id,
      target_id: target.id,
      target_type: target.class.name
    )
  end
end

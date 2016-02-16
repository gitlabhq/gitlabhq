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
  #  * creates a pending task for assignee if issue is assigned
  #
  def new_issue(issue, current_user)
    new_issuable(issue, current_user)
  end

  # When close an issue we should:
  #
  #  * mark all pending tasks related to the target for the current user as done
  #
  def close_issue(issue, current_user)
    mark_as_done(issue, current_user)
  end

  # When we reassign an issue we should:
  #
  #  * creates a pending task for new assignee if issue is assigned
  #
  def reassigned_issue(issue, current_user)
    reassigned_issuable(issue, current_user)
  end

  # When create a merge request we should:
  #
  #  * creates a pending task for assignee if merge request is assigned
  #
  def new_merge_request(merge_request, current_user)
    new_issuable(merge_request, current_user)
  end

  # When close a merge request we should:
  #
  #  * mark all pending tasks related to the target for the current user as done
  #
  def close_merge_request(merge_request, current_user)
    mark_as_done(merge_request, current_user)
  end

  # When we reassign a merge request we should:
  #
  #  * creates a pending task for new assignee if merge request is assigned
  #
  def reassigned_merge_request(merge_request, current_user)
    reassigned_issuable(merge_request, current_user)
  end

  # When we mark a task as done we should:
  #
  #  * mark all pending tasks related to the target for the user as done
  #
  def mark_as_done(target, user)
    pending_tasks = pending_tasks_for(user, target.project, target)
    pending_tasks.update_all(state: :done)
  end

  # When create a note we should:
  #
  #  * mark all pending tasks related to the noteable for the note author as done
  #
  def new_note(note)
    # Skip system notes, like status changes and cross-references
    unless note.system
      mark_as_done(note.noteable, note.author)
    end
  end

  # When update a note we should:
  #
  #  * mark all pending tasks related to the noteable for the current user as done
  #
  def update_note(note, current_user)
    # Skip system notes, like status changes and cross-references
    unless note.system
      mark_as_done(note.noteable, current_user)
    end
  end

  private

  def create_task(project, target, author, user, action)
    attributes = {
      project: project,
      user_id: user.id,
      author_id: author.id,
      target_id: target.id,
      target_type: target.class.name,
      action: action
    }

    Task.create(attributes)
  end

  def pending_tasks_for(user, project, target)
    user.tasks.pending.where(project: project, target: target)
  end

  def new_issuable(issuable, user)
    if issuable.is_assigned? && issuable.assignee != user
      create_task(issuable.project, issuable, user, issuable.assignee, Task::ASSIGNED)
    end
  end

  def reassigned_issuable(issuable, user)
    if issuable.is_assigned?
      create_task(issuable.project, issuable, user, issuable.assignee, Task::ASSIGNED)
    end
  end
end

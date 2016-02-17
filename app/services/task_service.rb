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
    mark_pending_tasks_as_done(issue, current_user)
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
    mark_pending_tasks_as_done(merge_request, current_user)
  end

  # When we reassign a merge request we should:
  #
  #  * creates a pending task for new assignee if merge request is assigned
  #
  def reassigned_merge_request(merge_request, current_user)
    reassigned_issuable(merge_request, current_user)
  end

  # When merge a merge request we should:
  #
  #  * mark all pending tasks related to the target for the current user as done
  #
  def merge_merge_request(merge_request, current_user)
    mark_pending_tasks_as_done(merge_request, current_user)
  end

  # When we mark a task as done we should:
  #
  #  * mark all pending tasks related to the target for the user as done
  #
  def mark_pending_tasks_as_done(target, user)
    pending_tasks(user, target.project, target).update_all(state: :done)
  end

  # When create a note we should:
  #
  #  * mark all pending tasks related to the noteable for the note author as done
  #
  def new_note(note)
    # Skip system notes, like status changes and cross-references
    unless note.system
      project = note.project
      target  = note.noteable
      author  = note.author

      mark_pending_tasks_as_done(target, author)

      mentioned_users = build_mentioned_users(project, note, author)

      mentioned_users.each do |user|
        create_task(project, target, author, user, Task::MENTIONED, note)
      end
    end
  end

  # When update a note we should:
  #
  #  * mark all pending tasks related to the noteable for the current user as done
  #
  def update_note(note, current_user)
    # Skip system notes, like status changes and cross-references
    unless note.system
      mark_pending_tasks_as_done(note.noteable, current_user)
    end
  end

  private

  def create_task(project, target, author, user, action, note = nil)
    attributes = {
      project: project,
      user_id: user.id,
      author_id: author.id,
      target_id: target.id,
      target_type: target.class.name,
      action: action,
      note: note
    }

    Task.create(attributes)
  end

  def build_mentioned_users(project, target, author)
    mentioned_users = target.mentioned_users.select do |user|
      user.can?(:read_project, project)
    end

    mentioned_users.delete(author)
    mentioned_users.delete(target.assignee) if target.respond_to?(:assignee)

    mentioned_users.uniq
  end

  def pending_tasks(user, project, target)
    user.tasks.pending.where(project: project, target: target)
  end

  def new_issuable(issuable, current_user)
    project = issuable.project
    target  = issuable
    author  = issuable.author

    if target.is_assigned? && target.assignee != current_user
      create_task(project, target, author, target.assignee, Task::ASSIGNED)
    end

    mentioned_users = build_mentioned_users(project, target, author)

    mentioned_users.each do |mentioned_user|
      create_task(project, target, author, mentioned_user, Task::MENTIONED)
    end
  end

  def reassigned_issuable(issuable, user)
    if issuable.is_assigned?
      create_task(issuable.project, issuable, user, issuable.assignee, Task::ASSIGNED)
    end
  end
end

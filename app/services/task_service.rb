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
    if issue.is_assigned? && issue.assignee != current_user
      create_task(issue.project, issue, current_user, issue.assignee, Task::ASSIGNED)
    end
  end

  # When we reassign an issue we should:
  #
  #  * creates a pending task for new assignee if issue is assigned
  #
  def reassigned_issue(issue, current_user)
    if issue.is_assigned?
      create_task(issue.project, issue, current_user, issue.assignee, Task::ASSIGNED)
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
end

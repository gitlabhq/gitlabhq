# NotificationService class
#
# Used for notifing users with emails about different events
#
# Ex.
#   NotificationService.new.new_issue(issue, current_user)
#
class NotificationService
  # Always notify user about ssh key added
  # only if ssh key is not deploy key
  def new_key(key)
    if key.user
      Notify.delay.new_ssh_key_email(key.id)
    end
  end

  # TODO: When we close an issue we should send next emails:
  #
  #  * issue author if his notification level is not Disabled
  #  * issue assignee if his notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def close_issue(issue, current_user)
    recipients = [issue.author, issue.assignee].compact.uniq

    # Dont send email to me when I close an issue
    recipients.reject! { |u| u == current_user }

    recipients.each do |recipient|
      Notify.delay.issue_status_changed_email(recipient.id, issue.id, issue.state, current_user.id)
    end
  end

  # When we reassign an issue we should send next emails:
  #
  #  * issue old assignee if his notification level is not Disabled
  #  * issue new assignee if his notification level is not Disabled
  #
  def reassigned_issue(issue, current_user)
    recipient_ids = [issue.assignee_id, issue.assignee_id_was].compact.uniq

    # Reject me from recipients if I reassign an issue
    recipient_ids.reject! { |id| id == current_user.id }

    recipient_ids.each do |recipient_id|
      Notify.delay.reassigned_issue_email(recipient_id, issue.id, issue.assignee_id_was)
    end
  end

  # When create an issue we should send next emails:
  #
  #  * issue assignee if his notification level is not Disabled
  #
  def new_issue(issue, current_user)
    if issue.assignee && issue.assignee != current_user
      Notify.delay.new_issue_email(issue.id)
    end
  end

  # When create a merge request we should send next emails:
  #
  #  * mr assignee if his notification level is not Disabled
  #
  def new_merge_request(merge_request, current_user)
    if merge_request.assignee && merge_request.assignee != current_user
      Notify.delay.new_merge_request_email(merge_request.id)
    end
  end

  # When we reassign a merge_request we should send next emails:
  #
  #  * merge_request old assignee if his notification level is not Disabled
  #  * merge_request assignee if his notification level is not Disabled
  #
  def reassigned_merge_request(merge_request, current_user)
    recipients_ids = merge_request.assignee_id_was, merge_request.assignee_id
    recipients_ids.delete current_user.id

    recipients_ids.each do |recipient_id|
      Notify.delay.reassigned_merge_request_email(recipient_id, merge_request.id, merge_request.assignee_id_was)
    end
  end

  # Notify new user with email after creation
  def new_user(user)
    # Dont email omniauth created users
    Notify.delay.new_user_email(user.id, user.password) unless user.extern_uid?
  end

  # Notify users on new note in system
  #
  # TODO: split on methods and refactor
  #
  def new_note(note)
    if note.notify
      users = note.project.users.reject { |u| u.id == note.author.id }

      # Note: wall posts are not "attached" to anything, so fall back to "Wall"
      noteable_type = note.noteable_type.presence || "Wall"
      notify_method = "note_#{noteable_type.underscore}_email".to_sym

      if Notify.respond_to? notify_method
        team_without_note_author(note).map do |u|
          Notify.delay.send(notify_method, u.id, note.id)
        end
      end
    elsif note.notify_author && note.commit_author
      Notify.delay.note_commit_email(note.commit_author.id, note.id)
    end
  end

  def new_team_member(users_project)
    Notify.delay.project_access_granted_email(users_project.id)
  end

  def update_team_member(users_project)
    Notify.delay.project_access_granted_email(users_project.id)
  end
end

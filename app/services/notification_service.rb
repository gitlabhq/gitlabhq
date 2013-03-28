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
  #
  # This is security email so it will be sent
  # even if user disabled notifications
  def new_key(key)
    if key.user
      Notify.delay.new_ssh_key_email(key.id)
    end
  end

  # When create an issue we should send next emails:
  #
  #  * issue assignee if his notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def new_issue(issue, current_user)
    new_resource_email(issue, 'new_issue_email')
  end

  # When we close an issue we should send next emails:
  #
  #  * issue author if his notification level is not Disabled
  #  * issue assignee if his notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def close_issue(issue, current_user)
    close_resource_email(issue, current_user, 'closed_issue_email')
  end

  # When we reassign an issue we should send next emails:
  #
  #  * issue old assignee if his notification level is not Disabled
  #  * issue new assignee if his notification level is not Disabled
  #
  def reassigned_issue(issue, current_user)
    reassign_resource_email(issue, current_user, 'reassigned_issue_email')
  end


  # When create a merge request we should send next emails:
  #
  #  * mr assignee if his notification level is not Disabled
  #
  def new_merge_request(merge_request, current_user)
    new_resource_email(merge_request, 'new_merge_request_email')
  end

  # When we reassign a merge_request we should send next emails:
  #
  #  * merge_request old assignee if his notification level is not Disabled
  #  * merge_request assignee if his notification level is not Disabled
  #
  def reassigned_merge_request(merge_request, current_user)
    reassign_resource_email(merge_request, current_user, 'reassigned_merge_request_email')
  end

  # When we close a merge request we should send next emails:
  #
  #  * merge_request author if his notification level is not Disabled
  #  * merge_request assignee if his notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def close_mr(merge_request, current_user)
    close_resource_email(merge_request, current_user, 'closed_merge_request_email')
  end

  # When we merge a merge request we should send next emails:
  #
  #  * merge_request author if his notification level is not Disabled
  #  * merge_request assignee if his notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def merge_mr(merge_request)
    recipients = reject_muted_users([merge_request.author, merge_request.assignee])
    recipients = recipients.concat(project_watchers(merge_request.project)).uniq

    recipients.each do |recipient|
      Notify.delay.merged_merge_request_email(recipient.id, merge_request.id)
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
    # ignore wall messages
    return true unless note.noteable_type.present?

    opts = { noteable_type: note.noteable_type, project_id: note.project_id }

    if note.commit_id
      opts.merge!(commit_id: note.commit_id)
      recipients = [note.commit_author]
    else
      opts.merge!(noteable_id: note.noteable_id)
      recipients = [note.noteable.try(:author), note.noteable.try(:assignee)]
    end

    # Get users who left comment in thread
    recipients = recipients.concat(User.where(id: Note.where(opts).pluck(:author_id)))

    # Merge project watchers
    recipients = recipients.concat(project_watchers(note.project)).compact.uniq

    # Reject mutes users
    recipients = reject_muted_users(recipients)

    # Reject author
    recipients.delete(note.author)

    # build notify method like 'note_commit_email'
    notify_method = "note_#{note.noteable_type.underscore}_email".to_sym

    recipients.each do |recipient|
      Notify.delay.send(notify_method, recipient.id, note.id)
    end
  end

  def new_team_member(users_project)
    Notify.delay.project_access_granted_email(users_project.id)
  end

  def update_team_member(users_project)
    Notify.delay.project_access_granted_email(users_project.id)
  end

  protected

  # Get project users with WATCH notification level
  def project_watchers(project)
    project.users.where(notification_level: Notification::N_WATCH)
  end

  # Remove users with disabled notifications from array
  # Also remove duplications and nil recipients
  def reject_muted_users(users)
    users.compact.uniq.reject do |user|
      user.notification.disabled?
    end
  end

  def new_resource_email(target, method)
    recipients = reject_muted_users([target.assignee])
    recipients = recipients.concat(project_watchers(target.project)).uniq
    recipients.delete(target.author)

    recipients.each do |recipient|
      Notify.delay.send(method, recipient.id, target.id)
    end
  end

  def close_resource_email(target, current_user, method)
    recipients = reject_muted_users([target.author, target.assignee])
    recipients = recipients.concat(project_watchers(target.project)).uniq
    recipients.delete(current_user)

    recipients.each do |recipient|
      Notify.delay.send(method, recipient.id, target.id, current_user.id)
    end
  end

  def reassign_resource_email(target, current_user, method)
    recipients = User.where(id: [target.assignee_id, target.assignee_id_was])

    # Add watchers to email list
    recipients = recipients.concat(project_watchers(target.project))

    # reject users with disabled notifications
    recipients = reject_muted_users(recipients)

    # Reject me from recipients if I reassign an item
    recipients.delete(current_user)

    recipients.each do |recipient|
      Notify.delay.send(method, recipient.id, target.id, target.assignee_id_was)
    end
  end
end

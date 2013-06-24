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
      mailer.new_ssh_key_email(key.id)
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
    recipients = reject_muted_users([merge_request.author, merge_request.assignee], merge_request.project)
    recipients = recipients.concat(project_watchers(merge_request.project)).uniq

    recipients.each do |recipient|
      mailer.merged_merge_request_email(recipient.id, merge_request.id)
    end
  end

  # Notify new user with email after creation
  def new_user(user)
    # Dont email omniauth created users
    mailer.new_user_email(user.id, user.password) unless user.extern_uid?
  end

  # Notify users on new note in system
  #
  # TODO: split on methods and refactor
  #
  def new_note(note)
    # ignore wall messages
    return true unless note.noteable_type.present?

    opts = { noteable_type: note.noteable_type, project_id: note.project_id }

    if note.commit_id.present?
      opts.merge!(commit_id: note.commit_id)
      recipients = [note.commit_author]
    else
      opts.merge!(noteable_id: note.noteable_id)
      target = note.noteable
      if target.respond_to?(:participants)
        recipients = target.participants
      else
        recipients = []
      end
    end

    # Get users who left comment in thread
    recipients = recipients.concat(User.where(id: Note.where(opts).pluck(:author_id)))

    # Merge project watchers
    recipients = recipients.concat(project_watchers(note.project)).compact.uniq

    # Reject mutes users
    recipients = reject_muted_users(recipients, note.project)

    # Reject author
    recipients.delete(note.author)

    # build notify method like 'note_commit_email'
    notify_method = "note_#{note.noteable_type.underscore}_email".to_sym

    recipients.each do |recipient|
      mailer.send(notify_method, recipient.id, note.id)
    end
  end

  def new_team_member(users_project)
    mailer.project_access_granted_email(users_project.id)
  end

  def update_team_member(users_project)
    mailer.project_access_granted_email(users_project.id)
  end

  protected

  # Get project users with WATCH notification level
  def project_watchers(project)

    # Get project notification settings since it has higher priority
    user_ids = project.users_projects.where(notification_level: Notification::N_WATCH).pluck(:user_id)
    project_watchers = User.where(id: user_ids)

    # next collect users who use global settings with watch state
    user_ids = project.users_projects.where(notification_level: Notification::N_GLOBAL).pluck(:user_id)
    project_watchers += User.where(id: user_ids, notification_level: Notification::N_WATCH)

    project_watchers.uniq
  end

  # Remove users with disabled notifications from array
  # Also remove duplications and nil recipients
  def reject_muted_users(users, project = nil)
    users = users.compact.uniq

    users.reject do |user|
      next user.notification.disabled? unless project

      tm = project.users_projects.find_by_user_id(user.id)

      # reject users who globally disabled notification and has no membership
      next user.notification.disabled? unless tm

      # reject users who disabled notification in project
      next true if tm.notification.disabled?

      # reject users who have N_GLOBAL in project and disabled in global settings
      tm.notification.global? && user.notification.disabled?
    end
  end

  def new_resource_email(target, method)
    if target.respond_to?(:participants)
      recipients = target.participants
    else
      recipients = []
    end
    recipients = reject_muted_users(recipients, target.project)
    recipients = recipients.concat(project_watchers(target.project)).uniq
    recipients.delete(target.author)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id)
    end
  end

  def close_resource_email(target, current_user, method)
    recipients = reject_muted_users([target.author, target.assignee], target.project)
    recipients = recipients.concat(project_watchers(target.project)).uniq
    recipients.delete(current_user)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, current_user.id)
    end
  end

  def reassign_resource_email(target, current_user, method)
    recipients = User.where(id: [target.assignee_id, target.assignee_id_was])

    # Add watchers to email list
    recipients = recipients.concat(project_watchers(target.project))

    # reject users with disabled notifications
    recipients = reject_muted_users(recipients, target.project)

    # Reject me from recipients if I reassign an item
    recipients.delete(current_user)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, target.assignee_id_was)
    end
  end

  def mailer
    Notify.delay
  end
end

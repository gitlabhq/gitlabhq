# NotificationService class
#
# Used for notifying users with emails about different events
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

  # Always notify user about email added to profile
  def new_email(email)
    if email.user
      mailer.new_email_email(email.id)
    end
  end

  # When create an issue we should send next emails:
  #
  #  * issue assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def new_issue(issue, current_user)
    new_resource_email(issue, issue.project, 'new_issue_email')
  end

  # When we close an issue we should send next emails:
  #
  #  * issue author if their notification level is not Disabled
  #  * issue assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def close_issue(issue, current_user)
    close_resource_email(issue, issue.project, current_user, 'closed_issue_email')
  end

  # When we reassign an issue we should send next emails:
  #
  #  * issue old assignee if their notification level is not Disabled
  #  * issue new assignee if their notification level is not Disabled
  #
  def reassigned_issue(issue, current_user)
    reassign_resource_email(issue, issue.project, current_user, 'reassigned_issue_email')
  end


  # When create a merge request we should send next emails:
  #
  #  * mr assignee if their notification level is not Disabled
  #
  def new_merge_request(merge_request, current_user)
    new_resource_email(merge_request, merge_request.target_project, 'new_merge_request_email')
  end

  # When we reassign a merge_request we should send next emails:
  #
  #  * merge_request old assignee if their notification level is not Disabled
  #  * merge_request assignee if their notification level is not Disabled
  #
  def reassigned_merge_request(merge_request, current_user)
    reassign_resource_email(merge_request, merge_request.target_project, current_user, 'reassigned_merge_request_email')
  end

  # When we close a merge request we should send next emails:
  #
  #  * merge_request author if their notification level is not Disabled
  #  * merge_request assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def close_mr(merge_request, current_user)
    close_resource_email(merge_request, merge_request.target_project, current_user, 'closed_merge_request_email')
  end

  def reopen_issue(issue, current_user)
    reopen_resource_email(issue, issue.project, current_user, 'issue_status_changed_email', 'reopened')
  end

  # When we merge a merge request we should send next emails:
  #
  #  * merge_request author if their notification level is not Disabled
  #  * merge_request assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def merge_mr(merge_request, current_user)
    recipients = reject_muted_users([merge_request.author, merge_request.assignee], merge_request.target_project)
    recipients = recipients.concat(project_watchers(merge_request.target_project)).uniq
    recipients.delete(current_user)

    recipients.each do |recipient|
      mailer.merged_merge_request_email(recipient.id, merge_request.id, current_user.id)
    end
  end

  def reopen_mr(merge_request, current_user)
    reopen_resource_email(merge_request, merge_request.target_project, current_user, 'merge_request_status_email', 'reopened')
  end

  # Notify new user with email after creation
  def new_user(user)
    # Don't email omniauth created users
    mailer.new_user_email(user.id, user.password) unless user.extern_uid?
  end

  # Notify users on new note in system
  #
  # TODO: split on methods and refactor
  #
  def new_note(note)
    return true unless note.noteable_type.present?

    # ignore gitlab service messages
    return true if note.note =~ /\A_Status changed to closed_/
    return true if note.note =~ /\A_mentioned in / && note.system == true

    opts = { noteable_type: note.noteable_type, project_id: note.project_id }

    target = note.noteable
    if target.respond_to?(:participants)
      recipients = target.participants
    else
      recipients = note.mentioned_users
    end

    if note.commit_id.present?
      opts.merge!(commit_id: note.commit_id)
      recipients << note.commit_author
    else
      opts.merge!(noteable_id: note.noteable_id)
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

  def new_group_member(users_group)
    mailer.group_access_granted_email(users_group.id)
  end

  def update_group_member(users_group)
    mailer.group_access_granted_email(users_group.id)
  end

  def project_was_moved(project)
    recipients = project.team.members
    recipients = reject_muted_users(recipients, project)

    recipients.each do |recipient|
      mailer.project_was_moved_email(project.id, recipient.id)
    end
  end

  protected

  # Get project users with WATCH notification level
  def project_watchers(project)
    project_members = users_project_notification(project)

    users_with_project_level_global = users_project_notification(project, Notification::N_GLOBAL)
    users_with_group_level_global = users_group_notification(project, Notification::N_GLOBAL)
    users = users_with_global_level_watch([users_with_project_level_global, users_with_group_level_global].flatten.uniq)

    users_with_project_setting = select_users_project_setting(project, users_with_project_level_global, users)
    users_with_group_setting = select_users_group_setting(project, project_members, users_with_group_level_global, users)

    User.where(id: users_with_project_setting.concat(users_with_group_setting).uniq).to_a
  end

  def users_project_notification(project, notification_level=nil)
    project_members = project.users_projects

    if notification_level
      project_members.where(notification_level: notification_level).pluck(:user_id)
    else
      project_members.pluck(:user_id)
    end
  end

  def users_group_notification(project, notification_level)
    if project.group
      project.group.users_groups.where(notification_level: notification_level).pluck(:user_id)
    else
      []
    end
  end

  def users_with_global_level_watch(ids)
    User.where(
      id: ids,
      notification_level: Notification::N_WATCH
    ).pluck(:id)
  end

  # Build a list of users based on project notifcation settings
  def select_users_project_setting(project, global_setting, users_global_level_watch)
    users = users_project_notification(project, Notification::N_WATCH)

    # If project setting is global, add to watch list if global setting is watch
    global_setting.each do |user_id|
      if users_global_level_watch.include?(user_id)
        users << user_id
      end
    end

    users
  end

  # Build a list of users based on group notifcation settings
  def select_users_group_setting(project, project_members, global_setting, users_global_level_watch)
    uids = users_group_notification(project, Notification::N_WATCH)

    # Group setting is watch, add to users list if user is not project member
    users = []
    uids.each do |user_id|
      if project_members.exclude?(user_id)
        users << user_id
      end
    end

    # Group setting is global, add to users list if global setting is watch
    global_setting.each do |user_id|
      if project_members.exclude?(user_id) && users_global_level_watch.include?(user_id)
        users << user_id
      end
    end

    users
  end

  # Remove users with disabled notifications from array
  # Also remove duplications and nil recipients
  def reject_muted_users(users, project = nil)
    users = users.to_a.compact.uniq

    users.reject do |user|
      next user.notification.disabled? unless project

      tm = project.users_projects.find_by(user_id: user.id)

      if !tm && project.group
        tm = project.group.users_groups.find_by(user_id: user.id)
      end

      # reject users who globally disabled notification and has no membership
      next user.notification.disabled? unless tm

      # reject users who disabled notification in project
      next true if tm.notification.disabled?

      # reject users who have N_GLOBAL in project and disabled in global settings
      tm.notification.global? && user.notification.disabled?
    end
  end

  def new_resource_email(target, project, method)
    if target.respond_to?(:participants)
      recipients = target.participants
    else
      recipients = []
    end
    recipients = reject_muted_users(recipients, project)
    recipients = recipients.concat(project_watchers(project)).uniq
    recipients.delete(target.author)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id)
    end
  end

  def close_resource_email(target, project, current_user, method)
    recipients = reject_muted_users([target.author, target.assignee], project)
    recipients = recipients.concat(project_watchers(project)).uniq
    recipients.delete(current_user)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, current_user.id)
    end
  end

  def reassign_resource_email(target, project, current_user, method)
    assignee_id_was = previous_record(target, "assignee_id")

    recipients = User.where(id: [target.assignee_id, assignee_id_was])

    # Add watchers to email list
    recipients = recipients.concat(project_watchers(project))

    # reject users with disabled notifications
    recipients = reject_muted_users(recipients, project)

    # Reject me from recipients if I reassign an item
    recipients.delete(current_user)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, assignee_id_was, current_user.id)
    end
  end

  def reopen_resource_email(target, project, current_user, method, status)
    recipients = reject_muted_users([target.author, target.assignee], project)
    recipients = recipients.concat(project_watchers(project)).uniq
    recipients.delete(current_user)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, status, current_user.id)
    end
  end

  def mailer
    Notify.delay
  end

  def previous_record(object, attribute)
    if object && attribute
      if object.previous_changes.include?(attribute)
        object.previous_changes[attribute].first
      end
    end
  end
end

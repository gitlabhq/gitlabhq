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
      mailer.new_ssh_key_email(key.id).deliver_later
    end
  end

  # Always notify user about email added to profile
  def new_email(email)
    if email.user
      mailer.new_email_email(email.id).deliver_later
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

  def close_mr(merge_request, current_user)
    close_resource_email(merge_request, merge_request.target_project, current_user, 'closed_merge_request_email')
  end

  def reopen_issue(issue, current_user)
    reopen_resource_email(issue, issue.project, current_user, 'issue_status_changed_email', 'reopened')
  end

  def merge_mr(merge_request, current_user)
    close_resource_email(
      merge_request,
      merge_request.target_project,
      current_user,
      'merged_merge_request_email'
    )
  end

  def reopen_mr(merge_request, current_user)
    reopen_resource_email(
      merge_request,
      merge_request.target_project,
      current_user, 'merge_request_status_email',
      'reopened'
    )
  end

  # Notify new user with email after creation
  def new_user(user, token = nil)
    # Don't email omniauth created users
    mailer.new_user_email(user.id, token).deliver_later unless user.identities.any?
  end

  # Notify users on new note in system
  #
  # TODO: split on methods and refactor
  #
  def new_note(note)
    return true unless note.noteable_type.present?

    # ignore gitlab service messages
    return true if note.note.start_with?('Status changed to closed')
    return true if note.cross_reference? && note.system == true
    return true if note.is_award

    target = note.noteable

    recipients = []

    mentioned_users = note.mentioned_users
    mentioned_users.select! do |user|
      user.can?(:read_project, note.project)
    end

    # Add all users participating in the thread (author, assignee, comment authors)
    participants =
      if target.respond_to?(:participants)
        target.participants(note.author)
      else
        mentioned_users
      end
    recipients = recipients.concat(participants)

    # Merge project watchers
    recipients = add_project_watchers(recipients, note.project)

    # Reject users with Mention notification level, except those mentioned in _this_ note.
    recipients = reject_mention_users(recipients - mentioned_users, note.project)
    recipients = recipients + mentioned_users

    recipients = reject_muted_users(recipients, note.project)

    recipients = add_subscribed_users(recipients, note.noteable)
    recipients = reject_unsubscribed_users(recipients, note.noteable)

    recipients.delete(note.author)
    recipients = recipients.uniq

    # build notify method like 'note_commit_email'
    notify_method = "note_#{note.noteable_type.underscore}_email".to_sym
    recipients.each do |recipient|
      mailer.send(notify_method, recipient.id, note.id).deliver_later
    end
  end

  def invite_project_member(project_member, token)
    mailer.project_member_invited_email(project_member.id, token).deliver_later
  end

  def accept_project_invite(project_member)
    mailer.project_invite_accepted_email(project_member.id).deliver_later
  end

  def decline_project_invite(project_member)
    mailer.project_invite_declined_email(
      project_member.project.id,
      project_member.invite_email,
      project_member.access_level,
      project_member.created_by_id
    ).deliver_later
  end

  def new_project_member(project_member)
    mailer.project_access_granted_email(project_member.id).deliver_later
  end

  def update_project_member(project_member)
    mailer.project_access_granted_email(project_member.id).deliver_later
  end

  def invite_group_member(group_member, token)
    mailer.group_member_invited_email(group_member.id, token).deliver_later
  end

  def accept_group_invite(group_member)
    mailer.group_invite_accepted_email(group_member.id).deliver_later
  end

  def decline_group_invite(group_member)
    mailer.group_invite_declined_email(
      group_member.group.id,
      group_member.invite_email,
      group_member.access_level,
      group_member.created_by_id
    ).deliver_later
  end

  def new_group_member(group_member)
    mailer.group_access_granted_email(group_member.id).deliver_later
  end

  def update_group_member(group_member)
    mailer.group_access_granted_email(group_member.id).deliver_later
  end

  def project_was_moved(project, old_path_with_namespace)
    recipients = project.team.members
    recipients = reject_muted_users(recipients, project)

    recipients.each do |recipient|
      mailer.project_was_moved_email(
        project.id,
        recipient.id,
        old_path_with_namespace
      ).deliver_later
    end
  end

  protected

  # Get project users with WATCH notification level
  def project_watchers(project)
    project_members = project_member_notification(project)

    users_with_project_level_global = project_member_notification(project, Notification::N_GLOBAL)
    users_with_group_level_global = group_member_notification(project, Notification::N_GLOBAL)
    users = users_with_global_level_watch([users_with_project_level_global, users_with_group_level_global].flatten.uniq)

    users_with_project_setting = select_project_member_setting(project, users_with_project_level_global, users)
    users_with_group_setting = select_group_member_setting(project, project_members, users_with_group_level_global, users)

    User.where(id: users_with_project_setting.concat(users_with_group_setting).uniq).to_a
  end

  def project_member_notification(project, notification_level=nil)
    project_members = project.project_members

    if notification_level
      project_members.where(notification_level: notification_level).pluck(:user_id)
    else
      project_members.pluck(:user_id)
    end
  end

  def group_member_notification(project, notification_level)
    if project.group
      project.group.group_members.where(notification_level: notification_level).pluck(:user_id)
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
  def select_project_member_setting(project, global_setting, users_global_level_watch)
    users = project_member_notification(project, Notification::N_WATCH)

    # If project setting is global, add to watch list if global setting is watch
    global_setting.each do |user_id|
      if users_global_level_watch.include?(user_id)
        users << user_id
      end
    end

    users
  end

  # Build a list of users based on group notification settings
  def select_group_member_setting(project, project_members, global_setting, users_global_level_watch)
    uids = group_member_notification(project, Notification::N_WATCH)

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

  def add_project_watchers(recipients, project)
    recipients.concat(project_watchers(project)).compact.uniq
  end

  # Remove users with disabled notifications from array
  # Also remove duplications and nil recipients
  def reject_muted_users(users, project = nil)
    reject_users(users, :disabled?, project)
  end

  # Remove users with notification level 'Mentioned'
  def reject_mention_users(users, project = nil)
    reject_users(users, :mention?, project)
  end

  # Reject users which method_name from notification object returns true.
  #
  # Example:
  #   reject_users(users, :watch?, project)
  #
  def reject_users(users, method_name, project = nil)
    users = users.to_a.compact.uniq
    users = users.reject(&:blocked?)

    users.reject do |user|
      next user.notification.send(method_name) unless project

      member = project.project_members.find_by(user_id: user.id)

      if !member && project.group
        member = project.group.group_members.find_by(user_id: user.id)
      end

      # reject users who globally set mention notification and has no membership
      next user.notification.send(method_name) unless member

      # reject users who set mention notification in project
      next true if member.notification.send(method_name)

      # reject users who have N_MENTION in project and disabled in global settings
      member.notification.global? && user.notification.send(method_name)
    end
  end

  def reject_unsubscribed_users(recipients, target)
    return recipients unless target.respond_to? :subscriptions

    recipients.reject do |user|
      subscription = target.subscriptions.find_by_user_id(user.id)
      subscription && !subscription.subscribed
    end
  end

  def add_subscribed_users(recipients, target)
    return recipients unless target.respond_to? :subscriptions

    subscriptions = target.subscriptions

    if subscriptions.any?
      recipients + subscriptions.where(subscribed: true).map(&:user)
    else
      recipients
    end
  end

  def new_resource_email(target, project, method)
    recipients = build_recipients(target, project, target.author)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id).deliver_later
    end
  end

  def close_resource_email(target, project, current_user, method)
    recipients = build_recipients(target, project, current_user)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, current_user.id).deliver_later
    end
  end

  def reassign_resource_email(target, project, current_user, method)
    previous_assignee_id = previous_record(target, 'assignee_id')
    previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id

    recipients = build_recipients(target, project, current_user, action: :reassign, previous_assignee: previous_assignee)

    recipients.each do |recipient|
      mailer.send(
        method,
        recipient.id,
        target.id,
        previous_assignee_id,
        current_user.id
      ).deliver_later
    end
  end

  def reopen_resource_email(target, project, current_user, method, status)
    recipients = build_recipients(target, project, current_user)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, status, current_user.id).deliver_later
    end
  end

  def build_recipients(target, project, current_user, action: nil, previous_assignee: nil)
    recipients = target.participants(current_user)

    recipients = add_project_watchers(recipients, project)
    recipients = reject_mention_users(recipients, project)

    # Re-assign is considered as a mention of the new assignee so we add the
    # new assignee to the list of recipients after we rejected users with
    # the "on mention" notification level
    if action == :reassign
      recipients << previous_assignee if previous_assignee
      recipients << target.assignee
    end

    recipients = reject_muted_users(recipients, project)
    recipients = add_subscribed_users(recipients, target)
    recipients = reject_unsubscribed_users(recipients, target)

    recipients.delete(current_user)

    recipients.uniq
  end

  def mailer
    Notify
  end

  def previous_record(object, attribute)
    if object && attribute
      if object.previous_changes.include?(attribute)
        object.previous_changes[attribute].first
      end
    end
  end
end

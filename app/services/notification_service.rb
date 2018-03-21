# rubocop:disable GitlabSecurity/PublicSend

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
  # even if user disabled notifications. However,
  # it won't be sent to internal users like the
  # ghost user or the EE support bot.
  def new_key(key)
    if key.user&.can?(:receive_notifications)
      mailer.new_ssh_key_email(key.id).deliver_later
    end
  end

  # Always notify the user about gpg key added
  #
  # This is a security email so it will be sent even if the user user disabled
  # notifications
  def new_gpg_key(gpg_key)
    if gpg_key.user&.can?(:receive_notifications)
      mailer.new_gpg_key_email(gpg_key.id).deliver_later
    end
  end

  # When create an issue we should send an email to:
  #
  #  * issue assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #  * watchers of the issue's labels
  #  * users with custom level checked with "new issue"
  #
  def new_issue(issue, current_user)
    new_resource_email(issue, :new_issue_email)
  end

  # When issue text is updated, we should send an email to:
  #
  #  * newly mentioned project team members with notification level higher than Participating
  #
  def new_mentions_in_issue(issue, new_mentioned_users, current_user)
    new_mentions_in_resource_email(
      issue,
      new_mentioned_users,
      current_user,
      :new_mention_in_issue_email
    )
  end

  # When we close an issue we should send an email to:
  #
  #  * issue author if their notification level is not Disabled
  #  * issue assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #  * users with custom level checked with "close issue"
  #
  def close_issue(issue, current_user)
    close_resource_email(issue, current_user, :closed_issue_email)
  end

  # When we reassign an issue we should send an email to:
  #
  #  * issue old assignee if their notification level is not Disabled
  #  * issue new assignee if their notification level is not Disabled
  #  * users with custom level checked with "reassign issue"
  #
  def reassigned_issue(issue, current_user, previous_assignees = [])
    recipients = NotificationRecipientService.build_recipients(
      issue,
      current_user,
      action: "reassign",
      previous_assignee: previous_assignees
    )

    previous_assignee_ids = previous_assignees.map(&:id)

    recipients.each do |recipient|
      mailer.send(
        :reassigned_issue_email,
        recipient.user.id,
        issue.id,
        previous_assignee_ids,
        current_user.id,
        recipient.reason
      ).deliver_later
    end
  end

  # When we add labels to an issue we should send an email to:
  #
  #  * watchers of the issue's labels
  #
  def relabeled_issue(issue, added_labels, current_user)
    relabeled_resource_email(issue, added_labels, current_user, :relabeled_issue_email)
  end

  # When create a merge request we should send an email to:
  #
  #  * mr assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #  * watchers of the mr's labels
  #  * users with custom level checked with "new merge request"
  #
  def new_merge_request(merge_request, current_user)
    new_resource_email(merge_request, :new_merge_request_email)
  end

  # When merge request text is updated, we should send an email to:
  #
  #  * newly mentioned project team members with notification level higher than Participating
  #
  def new_mentions_in_merge_request(merge_request, new_mentioned_users, current_user)
    new_mentions_in_resource_email(
      merge_request,
      new_mentioned_users,
      current_user,
      :new_mention_in_merge_request_email
    )
  end

  # When we reassign a merge_request we should send an email to:
  #
  #  * merge_request old assignee if their notification level is not Disabled
  #  * merge_request assignee if their notification level is not Disabled
  #  * users with custom level checked with "reassign merge request"
  #
  def reassigned_merge_request(merge_request, current_user)
    reassign_resource_email(merge_request, current_user, :reassigned_merge_request_email)
  end

  # When we add labels to a merge request we should send an email to:
  #
  #  * watchers of the mr's labels
  #
  def relabeled_merge_request(merge_request, added_labels, current_user)
    relabeled_resource_email(merge_request, added_labels, current_user, :relabeled_merge_request_email)
  end

  def close_mr(merge_request, current_user)
    close_resource_email(merge_request, current_user, :closed_merge_request_email)
  end

  def reopen_issue(issue, current_user)
    reopen_resource_email(issue, current_user, :issue_status_changed_email, 'reopened')
  end

  def merge_mr(merge_request, current_user)
    close_resource_email(
      merge_request,
      current_user,
      :merged_merge_request_email,
      skip_current_user: !merge_request.merge_when_pipeline_succeeds?
    )
  end

  def reopen_mr(merge_request, current_user)
    reopen_resource_email(
      merge_request,
      current_user,
      :merge_request_status_email,
      'reopened'
    )
  end

  def resolve_all_discussions(merge_request, current_user)
    recipients = NotificationRecipientService.build_recipients(
      merge_request,
      current_user,
      action: "resolve_all_discussions")

    recipients.each do |recipient|
      mailer.resolved_all_discussions_email(recipient.user.id, merge_request.id, current_user.id, recipient.reason).deliver_later
    end
  end

  # Notify new user with email after creation
  def new_user(user, token = nil)
    return true unless notifiable?(user, :mention)

    # Don't email omniauth created users
    mailer.new_user_email(user.id, token).deliver_later unless user.identities.any?
  end

  # Notify users on new note in system
  def new_note(note)
    return true unless note.noteable_type.present?

    # ignore gitlab service messages
    return true if note.cross_reference? && note.system?

    notify_method = "note_#{note.to_ability_name}_email".to_sym

    recipients = NotificationRecipientService.build_new_note_recipients(note)
    recipients.each do |recipient|
      mailer.send(notify_method, recipient.user.id, note.id).deliver_later
    end
  end

  # Members
  def new_access_request(member)
    return true unless member.notifiable?(:subscription)

    recipients = member.source.members.active_without_invites_and_requests.owners_and_masters
    if fallback_to_group_owners_masters?(recipients, member)
      recipients = member.source.group.members.active_without_invites_and_requests.owners_and_masters
    end

    recipients.each { |recipient| deliver_access_request_email(recipient, member) }
  end

  def decline_access_request(member)
    return true unless member.notifiable?(:subscription)

    mailer.member_access_denied_email(member.real_source_type, member.source_id, member.user_id).deliver_later
  end

  # Project invite
  def invite_project_member(project_member, token)
    return true unless project_member.notifiable?(:subscription)

    mailer.member_invited_email(project_member.real_source_type, project_member.id, token).deliver_later
  end

  def accept_project_invite(project_member)
    return true unless project_member.notifiable?(:subscription)

    mailer.member_invite_accepted_email(project_member.real_source_type, project_member.id).deliver_later
  end

  def decline_project_invite(project_member)
    mailer.member_invite_declined_email(
      project_member.real_source_type,
      project_member.project.id,
      project_member.invite_email,
      project_member.created_by_id
    ).deliver_later
  end

  def new_project_member(project_member)
    return true unless project_member.notifiable?(:mention, skip_read_ability: true)

    mailer.member_access_granted_email(project_member.real_source_type, project_member.id).deliver_later
  end

  def update_project_member(project_member)
    return true unless project_member.notifiable?(:mention)

    mailer.member_access_granted_email(project_member.real_source_type, project_member.id).deliver_later
  end

  # Group invite
  def invite_group_member(group_member, token)
    mailer.member_invited_email(group_member.real_source_type, group_member.id, token).deliver_later
  end

  def accept_group_invite(group_member)
    mailer.member_invite_accepted_email(group_member.real_source_type, group_member.id).deliver_later
  end

  def decline_group_invite(group_member)
    # always send this one, since it's a response to the user's own
    # action

    mailer.member_invite_declined_email(
      group_member.real_source_type,
      group_member.group.id,
      group_member.invite_email,
      group_member.created_by_id
    ).deliver_later
  end

  def new_group_member(group_member)
    return true unless group_member.notifiable?(:mention)

    mailer.member_access_granted_email(group_member.real_source_type, group_member.id).deliver_later
  end

  def update_group_member(group_member)
    return true unless group_member.notifiable?(:mention)

    mailer.member_access_granted_email(group_member.real_source_type, group_member.id).deliver_later
  end

  def project_was_moved(project, old_path_with_namespace)
    recipients = notifiable_users(project.team.members, :mention, project: project)

    recipients.each do |recipient|
      mailer.project_was_moved_email(
        project.id,
        recipient.id,
        old_path_with_namespace
      ).deliver_later
    end
  end

  def issue_moved(issue, new_issue, current_user)
    recipients = NotificationRecipientService.build_recipients(issue, current_user, action: 'moved')

    recipients.map do |recipient|
      email = mailer.issue_moved_email(recipient.user, issue, new_issue, current_user, recipient.reason)
      email.deliver_later
      email
    end
  end

  def project_exported(project, current_user)
    return true unless notifiable?(current_user, :mention, project: project)

    mailer.project_was_exported_email(current_user, project).deliver_later
  end

  def project_not_exported(project, current_user, errors)
    return true unless notifiable?(current_user, :mention, project: project)

    mailer.project_was_not_exported_email(current_user, project, errors).deliver_later
  end

  def pipeline_finished(pipeline, recipients = nil)
    email_template = "pipeline_#{pipeline.status}_email"

    return unless mailer.respond_to?(email_template)

    recipients ||= notifiable_users(
      [pipeline.user], :watch,
      custom_action: :"#{pipeline.status}_pipeline",
      target: pipeline
    ).map(&:notification_email)

    if recipients.any?
      mailer.public_send(email_template, pipeline, recipients).deliver_later
    end
  end

  def pages_domain_verification_succeeded(domain)
    recipients_for_pages_domain(domain).each do |user|
      mailer.pages_domain_verification_succeeded_email(domain, user).deliver_later
    end
  end

  def pages_domain_verification_failed(domain)
    recipients_for_pages_domain(domain).each do |user|
      mailer.pages_domain_verification_failed_email(domain, user).deliver_later
    end
  end

  def pages_domain_enabled(domain)
    recipients_for_pages_domain(domain).each do |user|
      mailer.pages_domain_enabled_email(domain, user).deliver_later
    end
  end

  def pages_domain_disabled(domain)
    recipients_for_pages_domain(domain).each do |user|
      mailer.pages_domain_disabled_email(domain, user).deliver_later
    end
  end

  protected

  def new_resource_email(target, method)
    recipients = NotificationRecipientService.build_recipients(target, target.author, action: "new")

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, recipient.reason).deliver_later
    end
  end

  def new_mentions_in_resource_email(target, new_mentioned_users, current_user, method)
    recipients = NotificationRecipientService.build_recipients(target, current_user, action: "new")
    recipients = recipients.select {|r| new_mentioned_users.include?(r.user) }

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, current_user.id, recipient.reason).deliver_later
    end
  end

  def close_resource_email(target, current_user, method, skip_current_user: true)
    action = method == :merged_merge_request_email ? "merge" : "close"

    recipients = NotificationRecipientService.build_recipients(
      target,
      current_user,
      action: action,
      skip_current_user: skip_current_user
    )

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, current_user.id, recipient.reason).deliver_later
    end
  end

  def reassign_resource_email(target, current_user, method)
    previous_assignee_id = previous_record(target, 'assignee_id')
    previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id

    recipients = NotificationRecipientService.build_recipients(
      target,
      current_user,
      action: "reassign",
      previous_assignee: previous_assignee
    )

    recipients.each do |recipient|
      mailer.send(
        method,
        recipient.user.id,
        target.id,
        previous_assignee_id,
        current_user.id,
        recipient.reason
      ).deliver_later
    end
  end

  def relabeled_resource_email(target, labels, current_user, method)
    recipients = labels.flat_map { |l| l.subscribers(target.project) }.uniq
    recipients = notifiable_users(
      recipients, :subscription,
      target: target,
      acting_user: current_user
    )

    label_names = labels.map(&:name)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, label_names, current_user.id).deliver_later
    end
  end

  def reopen_resource_email(target, current_user, method, status)
    recipients = NotificationRecipientService.build_recipients(target, current_user, action: "reopen")

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, status, current_user.id, recipient.reason).deliver_later
    end
  end

  def mailer
    Notify
  end

  def previous_record(object, attribute)
    return unless object && attribute

    if object.previous_changes.include?(attribute)
      object.previous_changes[attribute].first
    end
  end

  private

  def recipients_for_pages_domain(domain)
    project = domain.project

    return [] unless project

    notifiable_users(project.team.masters, :watch, target: project)
  end

  def notifiable?(*args)
    NotificationRecipientService.notifiable?(*args)
  end

  def notifiable_users(*args)
    NotificationRecipientService.notifiable_users(*args)
  end

  def deliver_access_request_email(recipient, member)
    mailer.member_access_requested_email(member.real_source_type, member.id, recipient.user.notification_email).deliver_later
  end

  def fallback_to_group_owners_masters?(recipients, member)
    return false if recipients.present?

    member.source.respond_to?(:group) && member.source.group
  end
end

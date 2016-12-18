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

  # When create an issue we should send an email to:
  #
  #  * issue assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #  * watchers of the issue's labels
  #  * users with custom level checked with "new issue"
  #
  def new_issue(issue, current_user)
    new_resource_email(issue, issue.project, :new_issue_email)
  end

  # When issue text is updated, we should send an email to:
  #
  #  * newly mentioned project team members with notification level higher than Participating
  #
  def new_mentions_in_issue(issue, new_mentioned_users, current_user)
    new_mentions_in_resource_email(
      issue,
      issue.project,
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
    close_resource_email(issue, issue.project, current_user, :closed_issue_email)
  end

  # When we reassign an issue we should send an email to:
  #
  #  * issue old assignee if their notification level is not Disabled
  #  * issue new assignee if their notification level is not Disabled
  #  * users with custom level checked with "reassign issue"
  #
  def reassigned_issue(issue, current_user)
    reassign_resource_email(issue, issue.project, current_user, :reassigned_issue_email)
  end

  # When we add labels to an issue we should send an email to:
  #
  #  * watchers of the issue's labels
  #
  def relabeled_issue(issue, added_labels, current_user)
    relabeled_resource_email(issue, issue.project, added_labels, current_user, :relabeled_issue_email)
  end

  # When create a merge request we should send an email to:
  #
  #  * mr assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #  * watchers of the mr's labels
  #  * users with custom level checked with "new merge request"
  #
  def new_merge_request(merge_request, current_user)
    new_resource_email(merge_request, merge_request.target_project, :new_merge_request_email)
  end

  # When merge request text is updated, we should send an email to:
  #
  #  * newly mentioned project team members with notification level higher than Participating
  #
  def new_mentions_in_merge_request(merge_request, new_mentioned_users, current_user)
    new_mentions_in_resource_email(
      merge_request,
      merge_request.target_project,
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
    reassign_resource_email(merge_request, merge_request.target_project, current_user, :reassigned_merge_request_email)
  end

  # When we add labels to a merge request we should send an email to:
  #
  #  * watchers of the mr's labels
  #
  def relabeled_merge_request(merge_request, added_labels, current_user)
    relabeled_resource_email(merge_request, merge_request.target_project, added_labels, current_user, :relabeled_merge_request_email)
  end

  def close_mr(merge_request, current_user)
    close_resource_email(merge_request, merge_request.target_project, current_user, :closed_merge_request_email)
  end

  def reopen_issue(issue, current_user)
    reopen_resource_email(issue, issue.project, current_user, :issue_status_changed_email, 'reopened')
  end

  def merge_mr(merge_request, current_user)
    close_resource_email(
      merge_request,
      merge_request.target_project,
      current_user,
      :merged_merge_request_email,
      skip_current_user: !merge_request.merge_when_build_succeeds?
    )
  end

  def reopen_mr(merge_request, current_user)
    reopen_resource_email(
      merge_request,
      merge_request.target_project,
      current_user,
      :merge_request_status_email,
      'reopened'
    )
  end

  def resolve_all_discussions(merge_request, current_user)
    recipients = build_recipients(merge_request, merge_request.target_project, current_user, action: "resolve_all_discussions")

    recipients.each do |recipient|
      mailer.resolved_all_discussions_email(recipient.id, merge_request.id, current_user.id).deliver_later
    end
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
    return true if note.cross_reference? && note.system?

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

    # Merge project with custom notification
    recipients = add_custom_notifications(recipients, note.project, :new_note)

    # Reject users with Mention notification level, except those mentioned in _this_ note.
    recipients = reject_mention_users(recipients - mentioned_users, note.project)
    recipients = recipients + mentioned_users

    recipients = reject_muted_users(recipients, note.project)

    recipients = add_subscribed_users(recipients, note.project, note.noteable)
    recipients = reject_unsubscribed_users(recipients, note.noteable)
    recipients = reject_users_without_access(recipients, note.noteable)

    recipients.delete(note.author)
    recipients = recipients.uniq

    # build notify method like 'note_commit_email'
    notify_method = "note_#{note.noteable_type.underscore}_email".to_sym

    recipients.each do |recipient|
      mailer.send(notify_method, recipient.id, note.id).deliver_later
    end
  end

  # Members
  def new_access_request(member)
    mailer.member_access_requested_email(member.real_source_type, member.id).deliver_later
  end

  def decline_access_request(member)
    mailer.member_access_denied_email(member.real_source_type, member.source_id, member.user_id).deliver_later
  end

  # Project invite
  def invite_project_member(project_member, token)
    mailer.member_invited_email(project_member.real_source_type, project_member.id, token).deliver_later
  end

  def accept_project_invite(project_member)
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
    mailer.member_access_granted_email(project_member.real_source_type, project_member.id).deliver_later
  end

  def update_project_member(project_member)
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
    mailer.member_invite_declined_email(
      group_member.real_source_type,
      group_member.group.id,
      group_member.invite_email,
      group_member.created_by_id
    ).deliver_later
  end

  def new_group_member(group_member)
    mailer.member_access_granted_email(group_member.real_source_type, group_member.id).deliver_later
  end

  def update_group_member(group_member)
    mailer.member_access_granted_email(group_member.real_source_type, group_member.id).deliver_later
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

  def issue_moved(issue, new_issue, current_user)
    recipients = build_recipients(issue, issue.project, current_user)

    recipients.map do |recipient|
      email = mailer.issue_moved_email(recipient, issue, new_issue, current_user)
      email.deliver_later
      email
    end
  end

  def project_exported(project, current_user)
    mailer.project_was_exported_email(current_user, project).deliver_later
  end

  def project_not_exported(project, current_user, errors)
    mailer.project_was_not_exported_email(current_user, project, errors).deliver_later
  end

  def pipeline_finished(pipeline, recipients = nil)
    email_template = "pipeline_#{pipeline.status}_email"

    return unless mailer.respond_to?(email_template)

    recipients ||= build_recipients(
      pipeline,
      pipeline.project,
      nil, # The acting user, who won't be added to recipients
      action: pipeline.status).map(&:notification_email)

    if recipients.any?
      mailer.public_send(email_template, pipeline, recipients).deliver_later
    end
  end

  protected

  # Get project/group users with CUSTOM notification level
  def add_custom_notifications(recipients, project, action)
    user_ids = []

    # Users with a notification setting on group or project
    user_ids += notification_settings_for(project, :custom, action)
    user_ids += notification_settings_for(project.group, :custom, action)

    # Users with global level custom
    users_with_project_level_global = notification_settings_for(project, :global)
    users_with_group_level_global   = notification_settings_for(project.group, :global)

    global_users_ids = users_with_project_level_global.concat(users_with_group_level_global)
    user_ids += users_with_global_level_custom(global_users_ids, action)

    recipients.concat(User.find(user_ids))
  end

  # Get project users with WATCH notification level
  def project_watchers(project)
    project_members = notification_settings_for(project)

    users_with_project_level_global = notification_settings_for(project, :global)
    users_with_group_level_global   = notification_settings_for(project.group, :global)

    users = users_with_global_level_watch([users_with_project_level_global, users_with_group_level_global].flatten.uniq)

    users_with_project_setting = select_project_member_setting(project, users_with_project_level_global, users)
    users_with_group_setting = select_group_member_setting(project, project_members, users_with_group_level_global, users)

    User.where(id: users_with_project_setting.concat(users_with_group_setting).uniq).to_a
  end

  def notification_settings_for(resource, notification_level = nil, action = nil)
    return [] unless resource

    if notification_level
      settings = resource.notification_settings.where(level: NotificationSetting.levels[notification_level])
      settings = settings.select { |setting| setting.events[action] } if action.present?
      settings.map(&:user_id)
    else
      resource.notification_settings.pluck(:user_id)
    end
  end

  def users_with_global_level_watch(ids)
    settings_with_global_level_of(:watch, ids).pluck(:user_id)
  end

  def users_with_global_level_custom(ids, action)
    settings = settings_with_global_level_of(:custom, ids)
    settings = settings.select { |setting| setting.events[action] }
    settings.map(&:user_id)
  end

  def settings_with_global_level_of(level, ids)
    NotificationSetting.where(
      user_id: ids,
      source_type: nil,
      level: NotificationSetting.levels[level]
    )
  end

  # Build a list of users based on project notification settings
  def select_project_member_setting(project, global_setting, users_global_level_watch)
    users = notification_settings_for(project, :watch)

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
    uids = notification_settings_for(project, :watch)

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
    recipients.concat(project_watchers(project)).compact
  end

  # Remove users with disabled notifications from array
  # Also remove duplications and nil recipients
  def reject_muted_users(users, project = nil)
    reject_users(users, :disabled, project)
  end

  # Remove users with notification level 'Mentioned'
  def reject_mention_users(users, project = nil)
    reject_users(users, :mention, project)
  end

  # Reject users which has certain notification level
  #
  # Example:
  #   reject_users(users, :watch, project)
  #
  def reject_users(users, level, project = nil)
    level = level.to_s

    unless NotificationSetting.levels.keys.include?(level)
      raise 'Invalid notification level'
    end

    users = users.to_a.compact.uniq
    users = users.reject(&:blocked?)

    users.reject do |user|
      global_notification_setting = user.global_notification_setting

      next global_notification_setting.level == level unless project

      setting = user.notification_settings_for(project)

      if !setting && project.group
        setting = user.notification_settings_for(project.group)
      end

      # reject users who globally set mention notification and has no setting per project/group
      next global_notification_setting.level == level unless setting

      # reject users who set mention notification in project
      next true if setting.level == level

      # reject users who have mention level in project and disabled in global settings
      setting.global? && global_notification_setting.level == level
    end
  end

  def reject_unsubscribed_users(recipients, target)
    return recipients unless target.respond_to? :subscriptions

    recipients.reject do |user|
      subscription = target.subscriptions.find_by_user_id(user.id)
      subscription && !subscription.subscribed
    end
  end

  def reject_users_without_access(recipients, target)
    ability = case target
              when Issuable
                :"read_#{target.to_ability_name}"
              when Ci::Pipeline
                :read_build # We have build trace in pipeline emails
              end

    return recipients unless ability

    recipients.select do |user|
      user.can?(ability, target)
    end
  end

  def add_subscribed_users(recipients, project, target)
    return recipients unless target.respond_to? :subscribers

    recipients + target.subscribers(project)
  end

  def add_labels_subscribers(recipients, project, target, labels: nil)
    return recipients unless target.respond_to? :labels

    (labels || target.labels).each do |label|
      recipients += label.subscribers(project)
    end

    recipients
  end

  def new_resource_email(target, project, method)
    recipients = build_recipients(target, project, target.author, action: "new")

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id).deliver_later
    end
  end

  def new_mentions_in_resource_email(target, project, new_mentioned_users, current_user, method)
    recipients = build_recipients(target, project, current_user, action: "new")
    recipients = recipients & new_mentioned_users

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, current_user.id).deliver_later
    end
  end

  def close_resource_email(target, project, current_user, method, skip_current_user: true)
    action = method == :merged_merge_request_email ? "merge" : "close"

    recipients = build_recipients(
      target,
      project,
      current_user,
      action: action,
      skip_current_user: skip_current_user
    )

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, current_user.id).deliver_later
    end
  end

  def reassign_resource_email(target, project, current_user, method)
    previous_assignee_id = previous_record(target, 'assignee_id')
    previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id

    recipients = build_recipients(target, project, current_user, action: "reassign", previous_assignee: previous_assignee)

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

  def relabeled_resource_email(target, project, labels, current_user, method)
    recipients = build_relabeled_recipients(target, project, current_user, labels: labels)
    label_names = labels.map(&:name)

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, label_names, current_user.id).deliver_later
    end
  end

  def reopen_resource_email(target, project, current_user, method, status)
    recipients = build_recipients(target, project, current_user, action: "reopen")

    recipients.each do |recipient|
      mailer.send(method, recipient.id, target.id, status, current_user.id).deliver_later
    end
  end

  def build_recipients(target, project, current_user, action: nil, previous_assignee: nil, skip_current_user: true)
    custom_action = build_custom_key(action, target)

    recipients = target.participants(current_user)
    recipients = add_project_watchers(recipients, project)

    recipients = add_custom_notifications(recipients, project, custom_action)
    recipients = reject_mention_users(recipients, project)

    recipients = recipients.uniq

    # Re-assign is considered as a mention of the new assignee so we add the
    # new assignee to the list of recipients after we rejected users with
    # the "on mention" notification level
    if [:reassign_merge_request, :reassign_issue].include?(custom_action)
      recipients << previous_assignee if previous_assignee
      recipients << target.assignee
    end

    recipients = reject_muted_users(recipients, project)
    recipients = add_subscribed_users(recipients, project, target)

    if [:new_issue, :new_merge_request].include?(custom_action)
      recipients = add_labels_subscribers(recipients, project, target)
    end

    recipients = reject_unsubscribed_users(recipients, target)
    recipients = reject_users_without_access(recipients, target)

    recipients.delete(current_user) if skip_current_user

    recipients.uniq
  end

  def build_relabeled_recipients(target, project, current_user, labels:)
    recipients = add_labels_subscribers([], project, target, labels: labels)
    recipients = reject_unsubscribed_users(recipients, target)
    recipients = reject_users_without_access(recipients, target)
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

  # Build event key to search on custom notification level
  # Check NotificationSetting::EMAIL_EVENTS
  def build_custom_key(action, object)
    "#{action}_#{object.class.model_name.name.underscore}".to_sym
  end
end

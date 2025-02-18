# frozen_string_literal: true

# rubocop:disable GitlabSecurity/PublicSend

# NotificationService class
#
# Used for notifying users with emails about different events
#
# Ex.
#   NotificationService.new.new_issue(issue, current_user)
#
# When calculating the recipients of a notification is expensive (for instance,
# in the new issue case), `#async` will make that calculation happen in Sidekiq
# instead:
#
#   NotificationService.new.async.new_issue(issue, current_user)
#
class NotificationService
  # These should not be called by the MailScheduler::NotificationServiceWorker -
  # what would it even mean?
  EXCLUDED_ACTIONS = %i[async].freeze

  def self.permitted_actions
    @permitted_actions ||= gitlab_extensions.flat_map do |klass|
      klass.public_instance_methods(false) - EXCLUDED_ACTIONS
    end.to_set
  end

  class Async
    attr_reader :parent

    delegate :respond_to_missing, to: :parent

    def initialize(parent)
      @parent = parent
    end

    def method_missing(meth, *args)
      return super unless parent.respond_to?(meth)

      MailScheduler::NotificationServiceWorker.perform_async(meth.to_s, *args)
    end
  end

  def async
    @async ||= Async.new(self)
  end

  def disabled_two_factor(user)
    return unless user.can?(:receive_notifications)

    mailer.disabled_two_factor_email(user).deliver_later
  end

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
  # This is a security email so it will be sent even if the user disabled
  # notifications
  def new_gpg_key(gpg_key)
    if gpg_key.user&.can?(:receive_notifications)
      mailer.new_gpg_key_email(gpg_key.id).deliver_later
    end
  end

  def bot_resource_access_token_about_to_expire(bot_user, token_name, params = {})
    resource = bot_user.resource_bot_resource

    bot_resource_access_token_about_to_expire_recipients(bot_user) do |recipient|
      next unless recipient.can?(:receive_notifications)

      log_info("Notifying resource access token owner about expiring tokens", recipient)

      mailer.bot_resource_access_token_about_to_expire_email(
        recipient,
        resource,
        token_name,
        params
      ).deliver_later
    end
  end

  # Notify the owner of the account when a new personal access token is created
  def access_token_created(user, token_name)
    return unless user.can?(:receive_notifications)

    mailer.access_token_created_email(user, token_name).deliver_later
  end

  # Notify the owner of the personal access token, when it is about to expire
  # And mark the token with about_to_expire_delivered
  def access_token_about_to_expire(user, token_names, params = {})
    return unless user.can?(:receive_notifications)

    log_info("Notifying User about expiring tokens", user)

    mailer.access_token_about_to_expire_email(user, token_names, params).deliver_later
  end

  # Notify the user when at least one of their personal access tokens has expired today
  def access_token_expired(user, token_names = [])
    return unless user.can?(:receive_notifications)

    mailer.access_token_expired_email(user, token_names).deliver_later
  end

  # Notify the user when one of their personal access tokens is revoked
  def access_token_revoked(user, token_name, source = nil)
    return unless user.can?(:receive_notifications)

    mailer.access_token_revoked_email(user, token_name, source).deliver_later
  end

  # Notify the user when at least one of their ssh key has expired today
  def ssh_key_expired(user, fingerprints)
    return unless user.can?(:receive_notifications)

    mailer.ssh_key_expired_email(user, fingerprints).deliver_later
  end

  # Notify the user when at least one of their ssh key is expiring soon
  def ssh_key_expiring_soon(user, fingerprints)
    return unless user.can?(:receive_notifications)

    mailer.ssh_key_expiring_soon_email(user, fingerprints).deliver_later
  end

  # Notify a user when a previously unknown IP or device is used to
  # sign in to their account
  def unknown_sign_in(user, ip, time, request_info)
    return unless user.can?(:receive_notifications)

    mailer.unknown_sign_in_email(user, ip, time, country: request_info.country, city: request_info.city).deliver_later
  end

  # Notify a user when a wrong 2FA OTP has been entered to
  # try to sign in to their account
  def two_factor_otp_attempt_failed(user, ip)
    return unless user.can?(:receive_notifications)

    mailer.two_factor_otp_attempt_failed_email(user, ip).deliver_later
  end

  # Notify a user when a new email address is added to the their account
  def new_email_address_added(user, email)
    return unless user.can?(:receive_notifications)

    mailer.new_email_address_added_email(user, email).deliver_later
  end

  # When create an issue we should send an email to:
  #
  #  * issue assignee if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #  * watchers of the issue's labels
  #  * users with custom level checked with "new issue"
  #
  def new_issue(issue, current_user)
    new_resource_email(issue, current_user, :new_issue_email)
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
  def close_issue(issue, current_user, params = {})
    close_resource_email(issue, current_user, :closed_issue_email, closed_via: params[:closed_via])
  end

  # When we reassign an issue we should send an email to:
  #
  #  * issue old assignees if their notification level is not Disabled
  #  * issue new assignees if their notification level is not Disabled
  #  * users with custom level checked with "reassign issue"
  #
  def reassigned_issue(issue, current_user, previous_assignees = [])
    recipients = NotificationRecipients::BuildService.build_recipients(
      issue,
      current_user,
      action: "reassign",
      previous_assignees: previous_assignees
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
  #  * mr author
  #  * mr assignees if their notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #  * watchers of the mr's labels
  #  * users with custom level checked with "new merge request"
  #
  # In EE, approvers of the merge request are also included
  def new_merge_request(merge_request, current_user)
    new_resource_email(merge_request, current_user, :new_merge_request_email)
  end

  NEW_COMMIT_EMAIL_DISPLAY_LIMIT = 20
  def push_to_merge_request(merge_request, current_user, new_commits: [], existing_commits: [])
    total_new_commits_count = new_commits.count
    truncated_new_commits = new_commits.first(NEW_COMMIT_EMAIL_DISPLAY_LIMIT).map do |commit|
      { short_id: commit.short_id, title: commit.title }
    end

    # We don't need the list of all existing commits. We need the first, the
    # last, and the total number of existing commits only.
    total_existing_commits_count = existing_commits.count
    existing_commits = [existing_commits.first, existing_commits.last] if total_existing_commits_count > 2
    existing_commits = existing_commits.map do |commit|
      { short_id: commit.short_id, title: commit.title }
    end

    recipients = NotificationRecipients::BuildService.build_recipients(merge_request, current_user, action: "push_to")

    recipients.each do |recipient|
      mailer.send(
        :push_to_merge_request_email,
        recipient.user.id, merge_request.id, current_user.id, recipient.reason,
        new_commits: truncated_new_commits, total_new_commits_count: total_new_commits_count,
        existing_commits: existing_commits, total_existing_commits_count: total_existing_commits_count
      ).deliver_later
    end
  end

  def change_in_merge_request_draft_status(merge_request, current_user)
    recipients = NotificationRecipients::BuildService.build_recipients(merge_request, current_user, action: "draft_status_change")

    recipients.each do |recipient|
      mailer.send(
        :change_in_merge_request_draft_status_email,
        recipient.user.id,
        merge_request.id,
        current_user.id,
        recipient.reason
      ).deliver_later
    end
  end

  # When a merge request is found to be unmergeable, we should send an email to:
  #
  #  * mr author
  #  * mr merge user if set
  #
  def merge_request_unmergeable(merge_request)
    merge_request_unmergeable_email(merge_request)
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
  #  * merge_request old assignees if their notification level is not Disabled
  #  * merge_request new assignees if their notification level is not Disabled
  #  * users with custom level checked with "reassign merge request"
  #
  def reassigned_merge_request(merge_request, current_user, previous_assignees = [])
    recipients = NotificationRecipients::BuildService.build_recipients(
      merge_request,
      current_user,
      action: "reassign",
      previous_assignees: previous_assignees
    )

    previous_assignee_ids = previous_assignees.map(&:id)

    recipients.each do |recipient|
      mailer.reassigned_merge_request_email(
        recipient.user.id,
        merge_request.id,
        previous_assignee_ids,
        current_user.id,
        recipient.reason
      ).deliver_later
    end
  end

  # When we change reviewer in a merge_request we should send an email to:
  #
  #  * merge_request old reviewers if their notification level is not Disabled
  #  * merge_request new reviewers if their notification level is not Disabled
  #  * users with custom level checked with "change reviewer merge request"
  #
  def changed_reviewer_of_merge_request(merge_request, current_user, previous_reviewers = [])
    recipients = NotificationRecipients::BuildService.build_recipients(
      merge_request,
      current_user,
      action: "change_reviewer",
      previous_assignees: previous_reviewers
    )

    previous_reviewer_ids = previous_reviewers.map(&:id)

    recipients.each do |recipient|
      mailer.changed_reviewer_of_merge_request_email(
        recipient.user.id,
        merge_request.id,
        previous_reviewer_ids,
        current_user.id,
        recipient.reason
      ).deliver_later
    end
  end

  def review_requested_of_merge_request(merge_request, current_user, reviewer)
    recipients = NotificationRecipients::BuildService.build_requested_review_recipients(merge_request, current_user, reviewer)

    deliver_option = review_request_deliver_options(merge_request.project)

    recipients.each do |recipient|
      mailer
        .request_review_merge_request_email(recipient.user.id, merge_request.id, current_user.id, recipient.reason)
        .deliver_later(deliver_option)
    end
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
      skip_current_user: !merge_request.auto_merge_enabled?
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
    recipients = NotificationRecipients::BuildService.build_recipients(
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
    return true if note.system_note_with_references?

    send_new_note_notifications(note)
    send_service_desk_notification(note)
  end

  def send_new_note_notifications(note)
    notify_method = "note_#{note.noteable_ability_name}_email".to_sym

    recipients = NotificationRecipients::BuildService.build_new_note_recipients(note)
    recipients.each do |recipient|
      mailer.send(notify_method, recipient.user.id, note.id, recipient.reason).deliver_later
    end
  end

  def send_service_desk_notification(note)
    return unless note.noteable_type == 'Issue'
    return if note.confidential
    return unless note.project && ::ServiceDesk.enabled?(note.project)

    issue = note.noteable
    recipients = issue.issue_email_participants

    return unless recipients.any?

    # Only populated if note is from external participant
    note_external_author = note.note_metadata&.email_participant&.downcase

    recipients.each do |recipient|
      # Don't send Service Desk notification if the recipient is the author of the note.
      # We store emails as-is but compare downcased versions.
      next if recipient.email.downcase == note_external_author

      mailer.service_desk_new_note_email(issue.id, note.id, recipient).deliver_later
      Gitlab::Metrics::BackgroundTransaction.current&.add_event(:service_desk_new_note_email)
    end
  end

  # Notify users when a new release is created
  def send_new_release_notifications(release)
    unless release.author&.can_trigger_notifications?
      warn_skipping_notifications(release.author, release)
      return false
    end

    recipients = NotificationRecipients::BuildService.build_recipients(release,
      release.author,
      action: "new")

    recipients.each do |recipient|
      mailer.new_release_email(recipient.user.id, release, recipient.reason).deliver_later
    end
  end

  def new_instance_access_request(user)
    recipients = User.instance_access_request_approvers_to_be_notified # https://gitlab.com/gitlab-org/gitlab/-/issues/277016 will change this

    return true if recipients.empty?

    recipients.each do |recipient|
      mailer.instance_access_request_email(user, recipient).deliver_later
    end
  end

  def user_admin_rejection(name, email)
    mailer.user_admin_rejection_email(name, email).deliver_later
  end

  def user_deactivated(name, email)
    mailer.user_deactivated_email(name, email).deliver_later
  end

  # Members
  def new_access_request(member)
    return true unless member.notifiable?(:subscription)

    recipients = member.source.access_request_approvers_to_be_notified

    return true if recipients.empty?

    recipients.each { |recipient| deliver_access_request_email(recipient, member) }
  end

  def new_member(member)
    notifiable_options = case member.source
                         when Group
                           {}
                         when Project
                           { skip_read_ability: true }
                         end

    return true unless member.notifiable?(:mention, notifiable_options)

    mailer.member_access_granted_email(member.real_source_type, member.id).deliver_later
  end

  def accept_invite(member)
    return true if member.source.is_a?(Project) && !member.notifiable?(:subscription)

    mailer.member_invite_accepted_email(member.real_source_type, member.id).deliver_later
  end

  def updated_member_access_level(member)
    return true unless member.notifiable?(:mention)

    mailer.member_access_granted_email(member.real_source_type, member.id).deliver_later
  end

  def updated_member_expiration(member)
    return true unless member.source.is_a?(Group)
    return true unless member.notifiable?(:mention)

    mailer.member_expiration_date_updated_email(member.real_source_type, member.id).deliver_later
  end

  def member_about_to_expire(member)
    return true unless member.notifiable?(:mention)

    mailer.member_about_to_expire_email(member.real_source_type, member.id).deliver_later
  end

  def project_was_moved(project, old_path_with_namespace)
    recipients = project_moved_recipients(project)
    recipients = notifiable_users(recipients, :custom, custom_action: :moved_project, project: project)

    recipients.each do |recipient|
      mailer.project_was_moved_email(
        project.id,
        recipient.id,
        old_path_with_namespace
      ).deliver_later
    end
  end

  def issue_moved(issue, new_issue, current_user)
    recipients = NotificationRecipients::BuildService.build_recipients(issue, current_user, action: 'moved')

    recipients.map do |recipient|
      email = mailer.issue_moved_email(recipient.user, issue, new_issue, current_user, recipient.reason)
      email.deliver_later
      email
    end
  end

  def issue_cloned(issue, new_issue, current_user)
    recipients = NotificationRecipients::BuildService.build_recipients(issue, current_user, action: 'cloned')

    recipients.map do |recipient|
      email = mailer.issue_cloned_email(recipient.user, issue, new_issue, current_user, recipient.reason)
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

  def pipeline_finished(pipeline, ref_status: nil, recipients: nil)
    # Must always check project configuration since recipients could be a list of emails
    # from the PipelinesEmailService integration.
    return if pipeline.project.emails_disabled?

    status = pipeline_notification_status(ref_status, pipeline)
    email_template = "pipeline_#{status}_email"

    return unless mailer.respond_to?(email_template)

    recipients ||= notifiable_users(
      [pipeline.user], :watch,
      custom_action: :"#{status}_pipeline",
      target: pipeline
    ).map do |user|
      user.notification_email_for(pipeline.project.group)
    end

    recipients.each do |recipient|
      mailer.public_send(email_template, pipeline, recipient).deliver_later
    end
  end

  def autodevops_disabled(pipeline, recipients)
    return if pipeline.project.emails_disabled?

    recipients.each do |recipient|
      mailer.autodevops_disabled_email(pipeline, recipient).deliver_later
    end
  end

  def pages_domain_verification_succeeded(domain)
    project_maintainers_recipients(domain, action: 'succeeded').each do |recipient|
      mailer.pages_domain_verification_succeeded_email(domain, recipient.user).deliver_later
    end
  end

  def pages_domain_verification_failed(domain)
    project_maintainers_recipients(domain, action: 'failed').each do |recipient|
      mailer.pages_domain_verification_failed_email(domain, recipient.user).deliver_later
    end
  end

  def pages_domain_enabled(domain)
    project_maintainers_recipients(domain, action: 'enabled').each do |recipient|
      mailer.pages_domain_enabled_email(domain, recipient.user).deliver_later
    end
  end

  def pages_domain_disabled(domain)
    project_maintainers_recipients(domain, action: 'disabled').each do |recipient|
      mailer.pages_domain_disabled_email(domain, recipient.user).deliver_later
    end
  end

  def pages_domain_auto_ssl_failed(domain)
    project_maintainers_recipients(domain, action: 'disabled').each do |recipient|
      mailer.pages_domain_auto_ssl_failed_email(domain, recipient.user).deliver_later
    end
  end

  def issue_due(issue)
    recipients = NotificationRecipients::BuildService.build_recipients(
      issue,
      issue.author,
      action: 'due',
      custom_action: :issue_due,
      skip_current_user: false
    )

    recipients.each do |recipient|
      mailer.send(:issue_due_email, recipient.user.id, issue.id, recipient.reason).deliver_later
    end
  end

  def repository_cleanup_success(project, user)
    return if project.emails_disabled?

    mailer.send(:repository_cleanup_success_email, project, user).deliver_later
  end

  def repository_cleanup_failure(project, user, error)
    return if project.emails_disabled?

    mailer.send(:repository_cleanup_failure_email, project, user, error).deliver_later
  end

  def repository_rewrite_history_success(project, user)
    return if project.emails_disabled?

    mailer.repository_rewrite_history_success_email(project, user).deliver_later
  end

  def repository_rewrite_history_failure(project, user, error)
    return if project.emails_disabled?

    mailer.repository_rewrite_history_failure_email(project, user, error).deliver_later
  end

  def remote_mirror_update_failed(remote_mirror)
    recipients = project_maintainers_recipients(remote_mirror, action: 'update_failed')

    recipients.each do |recipient|
      mailer.remote_mirror_update_failed_email(remote_mirror.id, recipient.user.id).deliver_later
    end
  end

  def prometheus_alerts_fired(project, alerts)
    return if project.emails_disabled?

    owners_and_maintainers_without_invites(project).to_a.product(alerts).each do |recipient, alert|
      mailer.prometheus_alert_fired_email(project, recipient.user, alert).deliver_later
    end
  end

  def group_was_exported(group, current_user)
    return true unless notifiable?(current_user, :mention, group: group)

    mailer.group_was_exported_email(current_user, group).deliver_later
  end

  def group_was_not_exported(group, current_user, errors)
    return true unless notifiable?(current_user, :mention, group: group)

    mailer.group_was_not_exported_email(current_user, group, errors).deliver_later
  end

  # Notify users on new review in system
  def new_review(review)
    recipients = NotificationRecipients::BuildService.build_new_review_recipients(review)
    deliver_options = new_review_deliver_options(review)

    recipients.each do |recipient|
      mailer
        .new_review_email(recipient.user.id, review.id)
        .deliver_later(deliver_options)
    end
  end

  def merge_when_pipeline_succeeds(merge_request, current_user)
    recipients = ::NotificationRecipients::BuildService.build_recipients(
      merge_request,
      current_user,
      action: 'merge_when_pipeline_succeeds',
      custom_action: :merge_when_pipeline_succeeds
    )

    recipients.each do |recipient|
      mailer.merge_when_pipeline_succeeds_email(recipient.user.id, merge_request.id, current_user.id).deliver_later
    end
  end

  def approve_mr(merge_request, current_user)
    approve_mr_email(merge_request, merge_request.target_project, current_user)
  end

  def unapprove_mr(merge_request, current_user)
    unapprove_mr_email(merge_request, merge_request.target_project, current_user)
  end

  def inactive_project_deletion_warning(project, deletion_date)
    owners_and_maintainers_without_invites(project).each do |recipient|
      mailer.inactive_project_deletion_warning_email(project, recipient.user, deletion_date).deliver_later
    end
  end

  def removed_milestone(target, current_user)
    method = case target
             when Issue
               :removed_milestone_issue_email
             when MergeRequest
               :removed_milestone_merge_request_email
             end

    recipients = NotificationRecipients::BuildService.build_recipients(
      target,
      current_user,
      action: 'removed_milestone'
    )

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, current_user.id).deliver_later
    end
  end

  def changed_milestone(target, milestone, current_user)
    method = case target
             when Issue
               :changed_milestone_issue_email
             when MergeRequest
               :changed_milestone_merge_request_email
             end

    recipients = NotificationRecipients::BuildService.build_recipients(
      target,
      current_user,
      action: 'changed_milestone'
    )

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, milestone, current_user.id).deliver_later
    end
  end

  def new_achievement_email(user, achievement)
    mailer.new_achievement_email(user, achievement)
  end

  protected

  def new_resource_email(target, current_user, method)
    unless current_user&.can_trigger_notifications?
      warn_skipping_notifications(current_user, target)
      return false
    end

    recipients = NotificationRecipients::BuildService.build_recipients(target, target.author, action: "new")

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, recipient.reason).deliver_later
    end
  end

  def new_mentions_in_resource_email(target, new_mentioned_users, current_user, method)
    unless current_user&.can_trigger_notifications?
      warn_skipping_notifications(current_user, target)
      return false
    end

    recipients = NotificationRecipients::BuildService.build_recipients(target, current_user, action: "new")
    recipients = recipients.select { |r| new_mentioned_users.include?(r.user) }

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, current_user.id, recipient.reason).deliver_later
    end
  end

  def close_resource_email(target, current_user, method, skip_current_user: true, closed_via: nil)
    action = method == :merged_merge_request_email ? "merge" : "close"

    recipients = NotificationRecipients::BuildService.build_recipients(
      target,
      current_user,
      action: action,
      skip_current_user: skip_current_user
    )

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, current_user.id, reason: recipient.reason, closed_via: closed_via).deliver_later
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
    recipients = NotificationRecipients::BuildService.build_recipients(target, current_user, action: "reopen")

    recipients.each do |recipient|
      mailer.send(method, recipient.user.id, target.id, status, current_user.id, recipient.reason).deliver_later
    end
  end

  def merge_request_unmergeable_email(merge_request)
    recipients = NotificationRecipients::BuildService.build_merge_request_unmergeable_recipients(merge_request)

    recipients.each do |recipient|
      mailer.merge_request_unmergeable_email(recipient.user.id, merge_request.id).deliver_later
    end
  end

  def mailer
    Notify
  end

  private

  def log_info(message_text, user)
    Gitlab::AppLogger.info(
      message: message_text,
      class: self.class,
      user_id: user.id
    )
  end

  def approve_mr_email(merge_request, project, current_user)
    recipients = ::NotificationRecipients::BuildService.build_recipients(merge_request, current_user, action: 'approve')

    recipients.each do |recipient|
      mailer.approved_merge_request_email(recipient.user.id, merge_request.id, current_user.id).deliver_later
    end
  end

  def unapprove_mr_email(merge_request, project, current_user)
    recipients = ::NotificationRecipients::BuildService.build_recipients(merge_request, current_user, action: 'unapprove')

    recipients.each do |recipient|
      mailer.unapproved_merge_request_email(recipient.user.id, merge_request.id, current_user.id).deliver_later
    end
  end

  def pipeline_notification_status(ref_status, pipeline)
    if Ci::Ref.failing_state?(ref_status)
      'failed'
    elsif ref_status
      ref_status
    else
      pipeline.status
    end
  end

  def owners_and_maintainers_without_invites(project)
    recipients = project.members.active_without_invites_and_requests.owners_and_maintainers

    if recipients.empty? && project.group
      recipients = project.group.members.active_without_invites_and_requests.owners_and_maintainers
    end

    recipients
  end

  def project_moved_recipients(project)
    finder = MembersFinder.new(project, nil, params: {
      active_without_invites_and_requests: true,
      owners_and_maintainers: true
    })
    finder.execute.preload_user_and_notification_settings.map(&:user)
  end

  def project_maintainers_recipients(target, action:)
    NotificationRecipients::BuildService.build_project_maintainers_recipients(target, action: action)
  end

  def bot_resource_access_token_about_to_expire_recipients(bot_user)
    resource = bot_user.resource_bot_resource

    if send_bot_rat_expiry_to_inherited?(resource)
      inherited_rat_members_relation(resource, bot_user).find_each do |user|
        yield user
      end
    else
      bot_user.resource_bot_owners_and_maintainers.find_each do |user|
        yield user
      end
    end
  end

  def inherited_rat_members_relation(resource, bot_user)
    finder = case resource
             when Group
               GroupMembersFinder.new(
                 resource,
                 bot_user,
                 params: {
                   access_levels: [
                     Gitlab::Access::OWNER,
                     Gitlab::Access::ADMIN
                   ],
                   non_invite: true
                 }
               ).execute(include_relations: [:direct, :inherited])
             when Project
               MembersFinder
                 .new(
                   resource,
                   bot_user,
                   params: {
                     owners_and_maintainers: true,
                     active_without_invites_and_requests: true
                   }
                 ).execute(include_relations: [:direct, :inherited])
             else
               raise ArgumentError, "#{bot_user} is not connected to a Group or Project"
             end

    User.id_in(finder.distinct(false).reselect('DISTINCT user_id')) # rubocop:disable CodeReuse/ActiveRecord -- moving this to the finder or model adds a lot of complexity and risk
  end

  def send_bot_rat_expiry_to_inherited?(group_or_project)
    root_ancestor = group_or_project.root_ancestor
    namespace = group_or_project.is_a?(Namespace) ? group_or_project : group_or_project.namespace

    Feature.enabled?(:pat_expiry_inherited_members_notification, root_ancestor) &&
      namespace.resource_access_token_notify_inherited?
  end

  def notifiable?(...)
    NotificationRecipients::BuildService.notifiable?(...)
  end

  def notifiable_users(...)
    NotificationRecipients::BuildService.notifiable_users(...)
  end

  def deliver_access_request_email(recipient, member)
    mailer.member_access_requested_email(member.real_source_type, member.id, recipient.user.id).deliver_later
  end

  def warn_skipping_notifications(user, object)
    Gitlab::AppLogger.warn(message: "Skipping sending notifications", user: user.id, klass: object.class.to_s, object_id: object.id)
  end

  def new_review_deliver_options(review)
    # Overridden in EE
    {}
  end

  def review_request_deliver_options(project)
    # Overridden in EE
    {}
  end
end

NotificationService.prepend_mod_with('NotificationService')

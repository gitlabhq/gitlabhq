require 'ee/gitlab/service_desk'

module EE
  module NotificationService
    extend ::Gitlab::Utils::Override

    # When we add approvers to a merge request we should send an email to:
    #
    #  * the new approvers
    #
    def add_merge_request_approvers(merge_request, new_approvers, current_user)
      add_mr_approvers_email(merge_request, new_approvers, current_user)
    end

    def approve_mr(merge_request, current_user)
      approve_mr_email(merge_request, merge_request.target_project, current_user)
    end

    def unapprove_mr(merge_request, current_user)
      unapprove_mr_email(merge_request, merge_request.target_project, current_user)
    end

    override :send_new_note_notifications
    def send_new_note_notifications(note)
      super
      send_service_desk_notification(note)
    end

    def mirror_was_hard_failed(project)
      recipients = project.members.active_without_invites_and_requests.owners_and_maintainers

      if recipients.empty? && project.group
        recipients = project.group.members.active_without_invites_and_requests.owners_and_maintainers
      end

      recipients.each do |recipient|
        mailer.mirror_was_hard_failed_email(project.id, recipient.user.id).deliver_later
      end
    end

    def new_epic(epic)
      new_resource_email(epic, :new_epic_email)
    end

    def project_mirror_user_changed(new_mirror_user, deleted_user_name, project)
      mailer.project_mirror_user_changed_email(new_mirror_user.id, deleted_user_name, project.id).deliver_later
    end

    def prometheus_alerts_fired(project, alerts)
      recipients = project.members.active_without_invites_and_requests.owners_and_masters

      if recipients.empty? && project.group
        recipients = project.group.members.active_without_invites_and_requests.owners_and_masters
      end

      recipients.to_a.product(alerts).each do |recipient, alert|
        mailer.prometheus_alert_fired_email(project.id, recipient.user.id, alert).deliver_later
      end
    end

    private

    def add_mr_approvers_email(merge_request, approvers, current_user)
      approvers.each do |approver|
        recipient = approver.user

        mailer.add_merge_request_approver_email(recipient.id, merge_request.id, current_user.id).deliver_later
      end
    end

    def approve_mr_email(merge_request, project, current_user)
      recipients = NotificationRecipientService.build_recipients(merge_request, current_user, action: 'approve')

      recipients.each do |recipient|
        mailer.approved_merge_request_email(recipient.user.id, merge_request.id, current_user.id).deliver_later
      end
    end

    def unapprove_mr_email(merge_request, project, current_user)
      recipients = NotificationRecipientService.build_recipients(merge_request, current_user, action: 'unapprove')

      recipients.each do |recipient|
        mailer.unapproved_merge_request_email(recipient.user.id, merge_request.id, current_user.id).deliver_later
      end
    end

    def send_service_desk_notification(note)
      return unless EE::Gitlab::ServiceDesk.enabled?
      return unless note.noteable_type == 'Issue'

      issue = note.noteable
      support_bot = ::User.support_bot

      return unless issue.service_desk_reply_to.present?
      return unless issue.project.service_desk_enabled?
      return if note.author == support_bot
      return unless issue.subscribed?(support_bot, issue.project)

      mailer.service_desk_new_note_email(issue.id, note.id).deliver_later
    end
  end
end

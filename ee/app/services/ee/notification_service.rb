require 'ee/gitlab/service_desk'

module EE
  module NotificationService
    # override
    def send_new_note_notifications(note)
      super
      send_service_desk_notification(note)
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

    def mirror_was_hard_failed(project)
      recipients = project.members.active_without_invites_and_requests.owners_and_masters

      if recipients.empty? && project.group
        recipients = project.group.members.active_without_invites_and_requests.owners_and_masters
      end

      recipients.each do |recipient|
        mailer.mirror_was_hard_failed_email(project.id, recipient.user.id).deliver_later
      end
    end

    def project_mirror_user_changed(new_mirror_user, deleted_user_name, project)
      mailer.project_mirror_user_changed_email(new_mirror_user.id, deleted_user_name, project.id).deliver_later
    end
  end
end

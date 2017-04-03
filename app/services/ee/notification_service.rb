require 'gitlab/ee/service_desk'

module EE
  module NotificationService
    # override
    def send_new_note_notifications(note)
      super
      send_service_desk_notification(note)
    end

    def send_service_desk_notification(note)
      return unless ::Gitlab::EE::ServiceDesk.enabled?
      return unless note.noteable_type == 'Issue'

      issue = note.noteable
      reply_to = issue.service_desk_reply_to

      return unless issue.service_desk_reply_to.present?
      return unless issue.project.service_desk_enabled?
      return if note.author == User.support_bot
      return unless issue.subscribed?(::User.support_bot, issue.project)

      Notify.service_desk_new_note_email(issue.id, note.id)
    end
  end
end

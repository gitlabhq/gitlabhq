module EE
  module NotificationService
    # override
    def send_new_note_notifications(note)
      super
      send_service_desk_notification(note)
    end

    def send_service_desk_notification(note)
      return true unless Gitlab::EE::ServiceDesk.enabled?
      return true unless note.noteable_type == 'Issue'
      issue = note.issuable
      reply_to = issue.service_desk_reply_to
      return nil unless issue.service_desk_reply_to.present?
      return nil unless issue.project.service_desk_enabled?

      return nil unless issue.subscribed?(user, issue.project)

      Notify.service_desk_new_note_email(issue.id, note.id)
    end
  end
end

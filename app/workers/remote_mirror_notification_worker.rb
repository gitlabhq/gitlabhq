# frozen_string_literal: true

class RemoteMirrorNotificationWorker
  include ApplicationWorker

  def perform(remote_mirror_id)
    remote_mirror = RemoteMirrorFinder.new(id: remote_mirror_id).execute

    # We check again if there's an error because a newer run since this job was
    # fired could've completed successfully.
    return unless remote_mirror && remote_mirror.last_error.present?
    return if remote_mirror.error_notification_sent?

    NotificationService.new.remote_mirror_update_failed(remote_mirror)

    remote_mirror.after_sent_notification
  end
end

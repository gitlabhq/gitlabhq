# frozen_string_literal: true

class RemoteMirrorNotificationWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management
  weight 2

  def perform(remote_mirror_id)
    remote_mirror = RemoteMirror.find_by_id(remote_mirror_id)

    # We check again if there's an error because a newer run since this job was
    # fired could've completed successfully.
    return unless remote_mirror && remote_mirror.last_error.present?
    return if remote_mirror.error_notification_sent?

    NotificationService.new.remote_mirror_update_failed(remote_mirror)

    remote_mirror.after_sent_notification
  end
end

module ObjectStorage
  class BackgroundMoveWorker
    include ApplicationWorker
    include ObjectStorageQueue

    sidekiq_options retry: 5

    def perform(uploader_class_name, subject_class_name, file_field, subject_id)
      uploader_class = uploader_class_name.constantize
      subject_class = subject_class_name.constantize

      return unless uploader_class < ObjectStorage::Concern
      return unless uploader_class.object_store_enabled?
      return unless uploader_class.background_upload_enabled?

      subject = subject_class.find(subject_id)
      uploader = build_uploader(subject, file_field&.to_sym)
      uploader.migrate!(ObjectStorage::Store::REMOTE)
    end

    def build_uploader(subject, mount_point)
      case subject
      when Upload then subject.build_uploader(mount_point)
      else
        subject.send(mount_point) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end

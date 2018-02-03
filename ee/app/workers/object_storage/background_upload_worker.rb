module ObjectStorage
  class BackgroundUploadWorker
    include ApplicationWorker
    include ObjectStorageQueue

    sidekiq_options retry: 5

    def perform(uploader_class_name, subject_class_name, file_field, subject_id)
      uploader_class = uploader_class_name.constantize
      subject_class = subject_class_name.constantize

      return unless uploader_class < ObjectStorage::Concern

      subject = subject_class.find(subject_id)
      uploader = build_uploader(subject, file_field&.to_sym)
      uploader.migrate!(ObjectStorage::Store::REMOTE)
    rescue RecordNotFound
      # does not retry when the record do not exists
      Rails.logger.warn("Cannot find subject #{subject_class} with id=#{subject_id}.")
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

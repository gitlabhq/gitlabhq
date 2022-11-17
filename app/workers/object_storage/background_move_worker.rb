# frozen_string_literal: true

module ObjectStorage
  class BackgroundMoveWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    include ObjectStorageQueue

    sidekiq_options retry: 5
    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
    loggable_arguments 0, 1, 2, 3

    def perform(uploader_class_name, subject_class_name, file_field, subject_id)
      uploader_class = uploader_class_name.constantize
      subject_class = subject_class_name.constantize
      mount_point = file_field&.to_sym

      return unless uploader_class < ObjectStorage::Concern
      return unless uploader_class.object_store_enabled?
      return unless uploader_class.background_upload_enabled?

      unless valid_mount_point?(subject_class, uploader_class, mount_point)
        raise(ArgumentError, "#{mount_point} not allowed for #{subject_class} in #{self.class.name}")
      end

      subject = subject_class.find(subject_id)
      uploader = build_uploader(subject, mount_point)
      uploader.migrate!(ObjectStorage::Store::REMOTE)
    end

    def build_uploader(subject, mount_point)
      case subject
      when Upload then subject.retrieve_uploader(mount_point)
      else
        # This is safe because:
        # 1. We don't pass any arguments to the method.
        # 2. valid_mount_point? checks that this is in fact an uploader of the correct class.
        #
        subject.public_send(mount_point) # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    def valid_mount_point?(subject_class, uploader_class, mount_point)
      subject_class == Upload || subject_class.uploaders[mount_point] == uploader_class
    end
  end
end

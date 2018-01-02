class ObjectStorageUploadWorker
  include ApplicationWorker

  sidekiq_options retry: 5

  def perform(uploader_class_name, subject_class_name, file_field, subject_id)
    uploader_class = uploader_class_name.constantize
    subject_class = subject_class_name.constantize

    return unless uploader_class.object_store_enabled?
    return unless uploader_class.background_upload_enabled?

    subject = subject_class.find_by(id: subject_id)
    return unless subject

    file = subject.public_send(file_field) # rubocop:disable GitlabSecurity/PublicSend

    return unless file.licensed?

    file.migrate!(uploader_class::REMOTE_STORE)
  end
end

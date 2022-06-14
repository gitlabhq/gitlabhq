# frozen_string_literal: true

class MetricImageUploader < GitlabUploader # rubocop:disable Gitlab/NamespacedClass
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads
  include UploaderHelper

  def self.workhorse_local_upload_path
    File.join(options.storage_path, 'uploads', TMP_UPLOAD_PATH)
  end

  private

  def dynamic_segment
    File.join(model.class.underscore, mounted_as.to_s, model.id.to_s)
  end

  class << self
    def default_store
      object_store_enabled? ? ObjectStorage::Store::REMOTE : ObjectStorage::Store::LOCAL
    end
  end
end

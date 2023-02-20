# frozen_string_literal: true

module ObjectStorage
  module S3
    def self.signed_head_url(file)
      fog_storage = ::Fog::Storage.new(file.fog_credentials)
      fog_dir = fog_storage.directories.new(key: file.fog_directory)
      fog_file = fog_dir.files.new(key: file.path)
      expire_at = ::Fog::Time.now + file.fog_authenticated_url_expiration

      fog_file.collection.head_url(fog_file.key, expire_at)
    end
  end
end

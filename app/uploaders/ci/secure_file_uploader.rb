# frozen_string_literal: true

module Ci
  class SecureFileUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_location :ci_secure_files

    # Use Lockbox to encrypt/decrypt the stored file (registers CarrierWave callbacks)
    encrypt(key: :key)

    def key
      Digest::SHA256.digest model.key_data
    end

    def checksum
      @checksum ||= Digest::SHA256.hexdigest(model.file.read)
    end

    def store_dir
      dynamic_segment
    end

    private

    def dynamic_segment
      Gitlab::HashedPath.new('secure_files', model.id, root_hash: model.project_id)
    end

    class << self
      # direct upload is disabled since the file
      # must always be encrypted
      def direct_upload_enabled?
        false
      end

      def default_store
        object_store_enabled? ? ObjectStorage::Store::REMOTE : ObjectStorage::Store::LOCAL
      end
    end
  end
end

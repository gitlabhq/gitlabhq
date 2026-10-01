# frozen_string_literal: true

module Ci
  class PipelineArtifactUploader < GitlabUploader
    include ObjectStorage::Concern
    include Gitlab::Encryption::DbKeyBaseLockboxKeys

    storage_location :artifacts

    # Use Lockbox to encrypt/decrypt the stored file (registers CarrierWave callbacks)
    encrypt(key: :encryption_key, previous_versions: :previous_encryption_key_versions)

    alias_method :lockbox_encrypt, :encrypt

    alias_method :upload, :model

    # Override Lockbox's encrypt to conditionally encrypt based on file_type
    def encrypt(file)
      return file unless model.pipeline_variables?

      lockbox_encrypt(file)
    end

    # Override Lockbox's read to conditionally decrypt based on file_type
    def read
      stored_data = super
      return unless stored_data

      if model.pipeline_variables?
        lockbox_notify("decrypt_file") { lockbox.decrypt(stored_data) }
      else
        stored_data
      end
    end

    def store_dir
      dynamic_segment
    end

    private

    def dynamic_segment
      Gitlab::HashedPath.new('pipelines', model.pipeline_id, 'artifacts', model.id, root_hash: model.project_id)
    end

    def encryption_key
      db_key_base_lockbox_key(encryption_key_context)
    end

    def previous_encryption_key_versions
      db_key_base_lockbox_previous_versions(encryption_key_context)
    end

    def encryption_key_context
      "pipeline_artifact:#{model.project_id}"
    end
  end
end

# frozen_string_literal: true

module Ci
  class PipelineArtifactUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_location :artifacts

    # Use Lockbox to encrypt/decrypt the stored file (registers CarrierWave callbacks)
    encrypt(key: :encryption_key)

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
      OpenSSL::HMAC.digest(
        'SHA256',
        Gitlab::Application.credentials.db_key_base,
        "pipeline_artifact:#{model.project_id}"
      )
    end
  end
end

# frozen_string_literal: true

module Terraform
  class StateUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_options Gitlab.config.terraform_state

    delegate :project_id, to: :model

    # Use Lockbox to encrypt/decrypt the stored file (registers CarrierWave callbacks)
    encrypt(key: :key)

    def filename
      "#{model.uuid}.tfstate"
    end

    def store_dir
      project_id.to_s
    end

    def key
      OpenSSL::HMAC.digest('SHA256', Gitlab::Application.secrets.db_key_base, project_id.to_s)
    end

    class << self
      def direct_upload_enabled?
        false
      end

      def background_upload_enabled?
        false
      end

      def proxy_download_enabled?
        true
      end

      def default_store
        object_store_enabled? ? ObjectStorage::Store::REMOTE : ObjectStorage::Store::LOCAL
      end
    end
  end
end

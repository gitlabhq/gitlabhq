# frozen_string_literal: true

module Terraform
  class StateUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_location :terraform_state

    delegate :terraform_state, :project_id, to: :model

    # Use Lockbox to encrypt/decrypt the stored file (registers CarrierWave callbacks)
    encrypt(key: :key)

    # On Cloud Native GitLab, /srv/gitlab/public/uploads/tmp is a shared mount.
    # Use a subpath from that directory to ensure the gitlab-workhorse and webservice
    # containers can both access this directory.
    def self.workhorse_local_upload_path
      Rails.root.join('public/uploads/tmp/terraform_state').to_s
    end

    def filename
      # This check is required to maintain backwards compatibility with
      # states that were created prior to versioning being supported.
      # This can be removed in 14.0 when support for these states is dropped.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/258960
      if terraform_state.versioning_enabled?
        "#{model.version}.tfstate"
      else
        "#{model.uuid}.tfstate"
      end
    end

    def store_dir
      # This check is required to maintain backwards compatibility with
      # states that were created prior to versioning being supported.
      # This can be removed in 14.0 when support for these states is dropped.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/258960
      if terraform_state.versioning_enabled?
        Gitlab::HashedPath.new(model.uuid, root_hash: project_id)
      else
        project_id.to_s
      end
    end

    def key
      OpenSSL::HMAC.digest('SHA256', Gitlab::Application.credentials.db_key_base, project_id.to_s)
    end

    class << self
      def direct_upload_enabled?
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

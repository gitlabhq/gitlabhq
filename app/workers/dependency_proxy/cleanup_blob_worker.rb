# frozen_string_literal: true

module DependencyProxy
  class CleanupBlobWorker
    include ApplicationWorker
    include ::Packages::CleanupArtifactWorker
    include Gitlab::Utils::StrongMemoize

    data_consistency :sticky

    queue_namespace :dependency_proxy_blob
    feature_category :virtual_registry
    urgency :low
    worker_resource_boundary :unknown
    idempotent!

    def max_running_jobs
      ::Gitlab::CurrentSettings.dependency_proxy_ttl_group_policy_worker_capacity
    end

    private

    def model
      DependencyProxy::Blob
    end

    def log_metadata(blob)
      log_extra_metadata_on_done(:dependency_proxy_blob_id, blob.id)
      log_extra_metadata_on_done(:group_id, blob.group_id)
    end

    def log_cleanup_item(blob)
      logger.info(
        structured_payload(
          group_id: blob.group_id,
          dependency_proxy_blob_id: blob.id
        )
      )
    end
  end
end

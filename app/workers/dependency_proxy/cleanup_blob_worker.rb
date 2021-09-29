# frozen_string_literal: true

module DependencyProxy
  class CleanupBlobWorker
    include ApplicationWorker
    include LimitedCapacity::Worker
    include Gitlab::Utils::StrongMemoize
    include DependencyProxy::CleanupWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :dependency_proxy_blob
    feature_category :dependency_proxy
    urgency :low
    worker_resource_boundary :unknown
    idempotent!

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

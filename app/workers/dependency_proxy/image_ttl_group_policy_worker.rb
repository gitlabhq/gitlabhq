# frozen_string_literal: true

module DependencyProxy
  class ImageTtlGroupPolicyWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :always

    feature_category :dependency_proxy

    UPDATE_BATCH_SIZE = 100

    def perform
      DependencyProxy::ImageTtlGroupPolicy.enabled.each do |policy|
        qualified_blobs = policy.group.dependency_proxy_blobs.active.read_before(policy.ttl)
        qualified_manifests = policy.group.dependency_proxy_manifests.active.read_before(policy.ttl)

        enqueue_blob_cleanup_job if expire_artifacts(qualified_blobs, DependencyProxy::Blob)
        enqueue_manifest_cleanup_job if expire_artifacts(qualified_manifests, DependencyProxy::Manifest)
      end

      log_counts
    end

    private

    def expire_artifacts(artifacts, model)
      rows_updated = false

      artifacts.each_batch(of: UPDATE_BATCH_SIZE) do |batch|
        rows = batch.update_all(status: :expired)
        rows_updated ||= rows > 0
      end

      rows_updated
    end

    def enqueue_blob_cleanup_job
      DependencyProxy::CleanupBlobWorker.perform_with_capacity
    end

    def enqueue_manifest_cleanup_job
      DependencyProxy::CleanupManifestWorker.perform_with_capacity
    end

    def log_counts
      use_replica_if_available do
        expired_blob_count = DependencyProxy::Blob.expired.count
        expired_manifest_count = DependencyProxy::Manifest.expired.count
        processing_blob_count = DependencyProxy::Blob.processing.count
        processing_manifest_count = DependencyProxy::Manifest.processing.count
        error_blob_count = DependencyProxy::Blob.error.count
        error_manifest_count = DependencyProxy::Manifest.error.count

        log_extra_metadata_on_done(:expired_dependency_proxy_blob_count, expired_blob_count)
        log_extra_metadata_on_done(:expired_dependency_proxy_manifest_count, expired_manifest_count)
        log_extra_metadata_on_done(:processing_dependency_proxy_blob_count, processing_blob_count)
        log_extra_metadata_on_done(:processing_dependency_proxy_manifest_count, processing_manifest_count)
        log_extra_metadata_on_done(:error_dependency_proxy_blob_count, error_blob_count)
        log_extra_metadata_on_done(:error_dependency_proxy_manifest_count, error_manifest_count)
      end
    end

    def use_replica_if_available(&block)
      ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries(&block)
    end
  end
end

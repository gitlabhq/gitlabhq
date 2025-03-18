# frozen_string_literal: true

module DependencyProxy
  class CleanupDependencyProxyWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :sticky
    idempotent!

    feature_category :virtual_registry

    def perform
      enqueue_blob_cleanup_job if DependencyProxy::Blob.pending_destruction.any?
      enqueue_manifest_cleanup_job if DependencyProxy::Manifest.pending_destruction.any?
    end

    private

    def enqueue_blob_cleanup_job
      DependencyProxy::CleanupBlobWorker.perform_with_capacity
    end

    def enqueue_manifest_cleanup_job
      DependencyProxy::CleanupManifestWorker.perform_with_capacity
    end
  end
end

DependencyProxy::CleanupDependencyProxyWorker.prepend_mod

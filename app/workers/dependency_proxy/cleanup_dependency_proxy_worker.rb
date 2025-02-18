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
      enqueue_vreg_packages_cache_entry_cleanup_job
    end

    private

    def enqueue_blob_cleanup_job
      DependencyProxy::CleanupBlobWorker.perform_with_capacity
    end

    def enqueue_manifest_cleanup_job
      DependencyProxy::CleanupManifestWorker.perform_with_capacity
    end

    def enqueue_vreg_packages_cache_entry_cleanup_job
      [::VirtualRegistries::Packages::Maven::Cache::Entry].each do |klass|
        if klass.pending_destruction.any?
          if Feature.enabled?(:virtual_registry_maven_cleanup_new_worker_class, Feature.current_request)
            ::VirtualRegistries::Packages::Cache::DestroyOrphanEntriesWorker.perform_with_capacity(klass.name)
          else
            ::VirtualRegistries::Packages::DestroyOrphanCachedResponsesWorker.perform_with_capacity(klass.name)
          end
        end
      end
    end
  end
end

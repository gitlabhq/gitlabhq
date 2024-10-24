# frozen_string_literal: true

module Packages
  class CleanupPackageRegistryWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :sticky
    idempotent!

    feature_category :package_registry

    def perform
      enqueue_package_file_cleanup_job if Packages::PackageFile.pending_destruction.exists?
      enqueue_cleanup_policy_jobs if Packages::Cleanup::Policy.runnable.exists?
      enqueue_cleanup_stale_npm_metadata_cache_job if Packages::Npm::MetadataCache.pending_destruction.exists?
      enqueue_cleanup_stale_nuget_symbols_job if Packages::Nuget::Symbol.pending_destruction.exists?

      log_counts
    end

    private

    def enqueue_package_file_cleanup_job
      Packages::CleanupPackageFileWorker.perform_with_capacity
    end

    def enqueue_cleanup_policy_jobs
      Packages::Cleanup::ExecutePolicyWorker.perform_with_capacity
    end

    def enqueue_cleanup_stale_npm_metadata_cache_job
      Packages::Npm::CleanupStaleMetadataCacheWorker.perform_with_capacity
    end

    def enqueue_cleanup_stale_nuget_symbols_job
      Packages::Nuget::CleanupStaleSymbolsWorker.perform_with_capacity
    end

    def log_counts
      pending_destruction_package_files_count = Packages::PackageFile.pending_destruction.count
      processing_package_files_count = Packages::PackageFile.processing.count
      error_package_files_count = Packages::PackageFile.error.count

      log_extra_metadata_on_done(:pending_destruction_package_files_count, pending_destruction_package_files_count)
      log_extra_metadata_on_done(:processing_package_files_count, processing_package_files_count)
      log_extra_metadata_on_done(:error_package_files_count, error_package_files_count)

      pending_cleanup_policies_count = Packages::Cleanup::Policy.runnable.count
      log_extra_metadata_on_done(:pending_cleanup_policies_count, pending_cleanup_policies_count)
    end
  end
end

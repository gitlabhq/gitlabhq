# frozen_string_literal: true

module Packages
  class CleanupPackageRegistryWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :sticky
    idempotent!

    feature_category :package_registry

    def perform
      # Each step runs even if an earlier one fails, so one failing query does not block the others
      # until the next cron run. The first error is re-raised afterwards so the job still logs as failed.
      failed = {}

      run_step(:package_file_cleanup, failed) do
        enqueue_package_file_cleanup_job if Packages::PackageFile.pending_destruction.exists?
      end
      run_step(:cleanup_policies, failed) do
        enqueue_cleanup_policy_jobs if Packages::Cleanup::Policy.runnable.exists?
      end
      run_step(:npm_metadata_cache_cleanup, failed) do
        enqueue_cleanup_stale_npm_metadata_cache_job if Packages::Npm::MetadataCache.pending_destruction.exists?
      end
      run_step(:helm_metadata_cache_cleanup, failed) do
        enqueue_cleanup_stale_helm_metadata_cache_job if Packages::Helm::MetadataCache.pending_destruction.exists?
      end
      run_step(:nuget_symbols_cleanup, failed) do
        enqueue_cleanup_stale_nuget_symbols_job if Packages::Nuget::Symbol.pending_destruction.exists?
      end

      run_step(:log_counts, failed) { log_counts }

      return if failed.empty?

      log_extra_metadata_on_done(:failed_steps, failed.keys)
      raise failed.each_value.first
    end

    private

    def run_step(step, failed)
      yield
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, step: step)
      failed[step] = e
    end

    def enqueue_package_file_cleanup_job
      Packages::CleanupPackageFileWorker.perform_with_capacity
    end

    def enqueue_cleanup_policy_jobs
      Packages::Cleanup::ExecutePolicyWorker.perform_with_capacity
    end

    def enqueue_cleanup_stale_npm_metadata_cache_job
      Packages::Npm::CleanupStaleMetadataCacheWorker.perform_with_capacity
    end

    def enqueue_cleanup_stale_helm_metadata_cache_job
      Packages::Helm::CleanupStaleMetadataCacheWorker.perform_with_capacity
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

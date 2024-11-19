# frozen_string_literal: true

module Packages
  class CleanupPackageFileWorker
    include ApplicationWorker
    include ::Packages::CleanupArtifactWorker
    include Gitlab::Utils::StrongMemoize

    data_consistency :sticky
    queue_namespace :package_cleanup
    feature_category :package_registry
    urgency :low
    worker_resource_boundary :unknown
    idempotent!

    def max_running_jobs
      ::Gitlab::CurrentSettings.packages_cleanup_package_file_worker_capacity
    end

    private

    def after_destroy
      pkg = artifact.package
      # Ml::ModelVersion need the package to be able to upload files later
      # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/461322
      return if pkg.ml_model?

      pkg.transaction do
        pkg.destroy if model.for_package_ids(pkg.id).empty?
      end
    end

    def model
      Packages::PackageFile
    end

    def next_item
      model.next_pending_destruction(order_by: :id)
    end

    def log_metadata(package_file)
      log_extra_metadata_on_done(:package_file_id, package_file.id)
      log_extra_metadata_on_done(:package_id, package_file.package_id)
    end

    def log_cleanup_item(package_file)
      logger.info(
        structured_payload(
          package_id: package_file.package_id,
          package_file_id: package_file.id
        )
      )
    end
  end
end

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

    delegate :package, :conan_file_metadatum, to: :artifact, private: true
    delegate :recipe_revision, :package_reference, :package_revision, to: :conan_file_metadatum, private: true

    def max_running_jobs
      ::Gitlab::CurrentSettings.packages_cleanup_package_file_worker_capacity
    end

    private

    def before_destroy
      # Load the metadatum into the memory for subsequent operations, since the metadatum is deleted
      # by CASCADE delete when package file is deleted.
      conan_file_metadatum if package.conan?
    end

    def after_destroy
      # Ml::ModelVersion need the package to be able to upload files later
      # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/461322
      return if package.ml_model?

      cleanup_conan_objects if package.conan?

      package.transaction do
        package.destroy if model.for_package_ids(package.id).empty?
      end
    end

    def model
      Packages::PackageFile
    end

    def next_item
      model.next_pending_destruction(order_by: :id)
    end

    def cleanup_conan_objects
      return unless conan_file_metadatum

      # return early as destroy will trigger the cascading delete
      return if recipe_revision&.orphan? && recipe_revision.destroy
      return if package_reference&.orphan? && package_reference.destroy

      package_revision.destroy if package_revision&.orphan?
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

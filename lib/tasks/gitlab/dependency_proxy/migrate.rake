# frozen_string_literal: true

desc "GitLab | Dependency Proxy | Migrate dependency proxy files to remote storage"
namespace :gitlab do
  namespace :dependency_proxy do
    task migrate: :environment do
      logger = Logger.new($stdout)
      logger.info('Starting transfer of dependency proxy files to object storage')

      unless ::DependencyProxy::FileUploader.object_store_enabled?
        raise 'Object store is disabled for dependency proxy feature'
      end

      ::DependencyProxy::Blob.with_files_stored_locally.find_each(batch_size: 10) do |blob_file|
        blob_file.file.migrate!(::DependencyProxy::FileUploader::Store::REMOTE)

        logger.info("Transferred dependency proxy blob file #{blob_file.id} of size #{blob_file.size.to_i.bytes} to object storage")
      rescue StandardError => e
        logger.error("Failed to transfer dependency proxy blob file #{blob_file.id} with error: #{e.message}")
      end

      ::DependencyProxy::Manifest.with_files_stored_locally.find_each(batch_size: 10) do |manifest_file|
        manifest_file.file.migrate!(::DependencyProxy::FileUploader::Store::REMOTE)

        logger.info("Transferred dependency proxy manifest file #{manifest_file.id} of size #{manifest_file.size.to_i.bytes} to object storage")
      rescue StandardError => e
        logger.error("Failed to transfer dependency proxy manifest file #{manifest_file.id} with error: #{e.message}")
      end
    end
  end
end

# frozen_string_literal: true

desc "GitLab | Packages | Migrate packages files to remote storage"
namespace :gitlab do
  namespace :packages do
    task migrate: :environment do
      require 'logger'

      logger = Logger.new($stdout)
      logger.info('Starting transfer of package files to object storage')

      unless ::Packages::PackageFileUploader.object_store_enabled?
        raise 'Object store is disabled for packages feature'
      end

      ::Packages::PackageFile.with_files_stored_locally.find_each(batch_size: 10) do |package_file|
        package_file.file.migrate!(::Packages::PackageFileUploader::Store::REMOTE)

        logger.info("Transferred package file #{package_file.id} of size #{package_file.size.to_i.bytes} to object storage")
      rescue StandardError => e
        logger.error("Failed to transfer package file #{package_file.id} with error: #{e.message}")
      end
    end
  end
end

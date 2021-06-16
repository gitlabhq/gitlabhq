# frozen_string_literal: true

require 'logger'

desc "GitLab | LFS | Migrate LFS objects to remote storage"
namespace :gitlab do
  namespace :lfs do
    task migrate: :environment do
      logger = Logger.new($stdout)
      logger.info('Starting transfer of LFS files to object storage')

      LfsObject.with_files_stored_locally
        .find_each(batch_size: 10) do |lfs_object|
        lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)

        logger.info("Transferred LFS object #{lfs_object.oid} of size #{lfs_object.size.to_i.bytes} to object storage")
      rescue StandardError => e
        logger.error("Failed to transfer LFS object #{lfs_object.oid} with error: #{e.message}")
      end
    end

    task migrate_to_local: :environment do
      logger = Logger.new($stdout)
      logger.info('Starting transfer of LFS files to local storage')

      LfsObject.with_files_stored_remotely
        .find_each(batch_size: 10) do |lfs_object|
        lfs_object.file.migrate!(LfsObjectUploader::Store::LOCAL)

        logger.info("Transferred LFS object #{lfs_object.oid} of size #{lfs_object.size.to_i.bytes} to local storage")
      rescue StandardError => e
        logger.error("Failed to transfer LFS object #{lfs_object.oid} with error: #{e.message}")
      end
    end
  end
end

require 'logger'

desc "GitLab | Migrate LFS objects to remote storage"
namespace :gitlab do
  namespace :lfs do
    task migrate: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting transfer of LFS files to object storage')

      LfsObject.with_files_stored_locally
        .find_each(batch_size: 10) do |lfs_object|
          begin
            lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)

            logger.info("Transferred LFS object #{lfs_object.oid} of size #{lfs_object.size.to_i.bytes} to object storage")
          rescue => e
            logger.error("Failed to transfer LFS object #{lfs_object.oid} with error: #{e.message}")
          end
        end
    end
  end
end

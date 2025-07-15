# frozen_string_literal: true

desc "GitLab | Packages | Migrate packages files between storage types"
namespace :gitlab do
  namespace :packages do
    task :migrate, [:to] => :environment do |_task, args|
      require 'logger'

      target = (args[:to] || 'remote').to_s.downcase

      unless %w[remote local].include?(target)
        puts "Error: Target must be 'remote' or 'local'"
        puts "Usage: rake 'gitlab:packages:migrate[remote]' or rake 'gitlab:packages:migrate[local]'"
        exit 1
      end

      logger = Logger.new($stdout)
      is_remote = target == 'remote'
      logger.info("Starting transfer of package files to #{target} storage")

      unless ::Packages::PackageFileUploader.object_store_enabled?
        raise 'Object store is disabled for packages feature'
      end

      scope, storage_target = if is_remote
                                [::Packages::PackageFile.with_files_stored_locally, ::Packages::PackageFileUploader::Store::REMOTE]
                              else
                                [::Packages::PackageFile.with_files_stored_remotely, ::Packages::PackageFileUploader::Store::LOCAL]
                              end

      scope.find_each(batch_size: 10) do |package_file|
        package_file.file.migrate!(storage_target)

        logger.info("Transferred package file #{package_file.id} of size #{package_file.size.to_i.bytes} to #{target} storage")
      rescue StandardError => e
        logger.error("Failed to transfer package file #{package_file.id} with error: #{e.message}")
      end
    end
  end
end

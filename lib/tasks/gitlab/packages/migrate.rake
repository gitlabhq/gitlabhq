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

      storage_target = is_remote ? ::Packages::PackageFileUploader::Store::REMOTE : ::Packages::PackageFileUploader::Store::LOCAL

      # All package-related models with file_store (ObjectStorable)
      migrate_configs = [
        [::Packages::PackageFile, 'package file'],
        [::Packages::Helm::MetadataCache, 'Helm metadata cache'],
        [::Packages::Npm::MetadataCache, 'NPM metadata cache'],
        [::Packages::Nuget::Symbol, 'NuGet symbol']
      ]
      migrate_configs.each do |model, name|
        scope = is_remote ? model.with_files_stored_locally : model.with_files_stored_remotely
        scope.find_each(batch_size: 10) do |record|
          record.file.migrate!(storage_target)
          extra = case record
                  when ::Packages::PackageFile then " of size #{record.size.to_i.bytes}"
                  when ::Packages::Helm::MetadataCache then " (project #{record.project_id}, channel #{record.channel})"
                  when ::Packages::Npm::MetadataCache then " (project #{record.project_id}, package #{record.package_name})"
                  else ""
                  end
          logger.info("Transferred #{name} #{record.id}#{extra} to #{target} storage")
        rescue StandardError => e
          logger.error("Failed to transfer #{name} #{record.id} with error: #{e.message}")
        end
      end
    end
  end
end

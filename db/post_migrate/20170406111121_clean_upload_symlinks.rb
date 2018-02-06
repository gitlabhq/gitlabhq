# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanUploadSymlinks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false
  DIRECTORIES_TO_MOVE = %w(user project note group appearance)

  def up
    return unless file_storage?

    DIRECTORIES_TO_MOVE.each do |dir|
      symlink_location = File.join(old_upload_dir, dir)
      next unless File.symlink?(symlink_location)

      say "removing symlink: #{symlink_location}"
      FileUtils.rm(symlink_location)
    end
  end

  def down
    return unless file_storage?

    DIRECTORIES_TO_MOVE.each do |dir|
      symlink = File.join(old_upload_dir, dir)
      destination = File.join(new_upload_dir, dir)

      next if File.directory?(symlink)
      next unless File.directory?(destination)

      say "Creating symlink #{symlink} -> #{destination}"
      FileUtils.ln_s(destination, symlink)
    end
  end

  def file_storage?
    CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
  end

  def base_directory
    Rails.root
  end

  def old_upload_dir
    File.join(base_directory, "public", "uploads")
  end

  def new_upload_dir
    File.join(base_directory, "public", "uploads", "-", "system")
  end
end

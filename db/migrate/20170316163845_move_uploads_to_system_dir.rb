# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MoveUploadsToSystemDir < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false
  DIRECTORIES_TO_MOVE = %w(user project note group appearance).freeze

  def up
    return unless file_storage?

    FileUtils.mkdir_p(new_upload_dir)

    DIRECTORIES_TO_MOVE.each do |dir|
      source = File.join(old_upload_dir, dir)
      destination = File.join(new_upload_dir, dir)
      next unless File.directory?(source)
      next if File.directory?(destination)

      say "Moving #{source} -> #{destination}"
      FileUtils.mv(source, destination)
      FileUtils.ln_s(destination, source)
    end
  end

  def down
    return unless file_storage?
    return unless File.directory?(new_upload_dir)

    DIRECTORIES_TO_MOVE.each do |dir|
      source = File.join(new_upload_dir, dir)
      destination = File.join(old_upload_dir, dir)
      next unless File.directory?(source)
      next if File.directory?(destination) && !File.symlink?(destination)

      say "Moving #{source} -> #{destination}"
      FileUtils.rm(destination) if File.symlink?(destination)
      FileUtils.mv(source, destination)
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

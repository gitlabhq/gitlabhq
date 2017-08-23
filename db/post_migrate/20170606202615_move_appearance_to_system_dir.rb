class MoveAppearanceToSystemDir < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false
  DIRECTORY_TO_MOVE = 'appearance'.freeze

  def up
    source = File.join(old_upload_dir, DIRECTORY_TO_MOVE)
    destination = File.join(new_upload_dir, DIRECTORY_TO_MOVE)

    move_directory(source, destination)
  end

  def down
    source = File.join(new_upload_dir, DIRECTORY_TO_MOVE)
    destination = File.join(old_upload_dir, DIRECTORY_TO_MOVE)

    move_directory(source, destination)
  end

  def move_directory(source, destination)
    unless file_storage?
      say 'Not using file storage, skipping'
      return
    end

    unless File.directory?(source)
      say "#{source} did not exist, skipping"
      return
    end

    if File.directory?(destination)
      say "#{destination} already existed, skipping"
      return
    end

    say "Moving #{source} -> #{destination}"
    FileUtils.mv(source, destination)
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

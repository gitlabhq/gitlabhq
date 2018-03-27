class MoveSystemUploadFolder < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    unless file_storage?
      say 'Using object storage, no need to move.'
      return
    end

    unless File.directory?(old_directory)
      say "#{old_directory} doesn't exist, no need to move it."
      return
    end

    if File.directory?(new_directory)
      say "#{new_directory} already exists. No need to redo the move."
      return
    end

    FileUtils.mkdir_p(File.join(base_directory, '-'))

    say "Moving #{old_directory} -> #{new_directory}"
    FileUtils.mv(old_directory, new_directory)
    FileUtils.ln_s(new_directory, old_directory)
  end

  def down
    unless file_storage?
      say 'Using object storage, no need to move.'
      return
    end

    unless File.directory?(new_directory)
      say "#{new_directory} doesn't exist, no need to move it."
      return
    end

    if !File.symlink?(old_directory) && File.directory?(old_directory)
      say "#{old_directory} already exists and is not a symlink, no need to revert."
      return
    end

    if File.symlink?(old_directory)
      say "Removing #{old_directory} -> #{new_directory} symlink"
      FileUtils.rm(old_directory)
    end

    say "Moving #{new_directory} -> #{old_directory}"
    FileUtils.mv(new_directory, old_directory)
  end

  def new_directory
    File.join(base_directory, '-', 'system')
  end

  def old_directory
    File.join(base_directory, 'system')
  end

  def base_directory
    File.join(Rails.root, 'public', 'uploads')
  end

  def file_storage?
    CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
  end
end

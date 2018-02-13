# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanupMoveSystemUploadFolderSymlink < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if File.symlink?(old_directory)
      say "Removing #{old_directory} -> #{new_directory} symlink"
      FileUtils.rm(old_directory)
    else
      say "Symlink #{old_directory} non existant, nothing to do."
    end
  end

  def down
    if File.directory?(new_directory)
      say "Symlinking #{old_directory} -> #{new_directory}"
      FileUtils.ln_s(new_directory, old_directory) unless File.exist?(old_directory)
    else
      say "#{new_directory} doesn't exist, skipping."
    end
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
end

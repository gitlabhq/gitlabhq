# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# Remove all files from old custom carrierwave's cache directories.
# See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9466

class RemoveOldCacheDirectories < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # FileUploader cache.
    FileUtils.rm_rf(Dir[Rails.root.join('public', 'uploads', 'tmp', '*')])
  end

  def down
    # Old cache is not supposed to be recoverable.
    # So the down method is empty.
  end
end

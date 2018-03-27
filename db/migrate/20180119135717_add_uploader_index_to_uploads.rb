# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddUploaderIndexToUploads < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :uploads, :path
    add_concurrent_index    :uploads, [:uploader, :path], using: :btree
  end

  def down
    remove_concurrent_index :uploads, [:uploader, :path]
    add_concurrent_index    :uploads, :path, using: :btree
  end
end

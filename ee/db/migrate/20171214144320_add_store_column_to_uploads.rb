# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddStoreColumnToUploads < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless column.exists?(:uploads, :store)
      add_column(:uploads, :store, :integer)
    end
  end

  def down
    if column.exists?(:uploads, :store)
      remove_column(:uploads, :store)
    end
  end
end

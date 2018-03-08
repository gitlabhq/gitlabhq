# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAllowMaintainerToPushToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :merge_requests, :allow_maintainer_to_push, :boolean
  end

  def down
    remove_column :merge_requests, :allow_maintainer_to_push
  end
end

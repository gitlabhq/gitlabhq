class OnlyAllowMergeIfAllDiscussionsAreResolved < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column :projects, :only_allow_merge_if_all_discussions_are_resolved, :boolean
  end

  def down
    remove_column(:projects, :only_allow_merge_if_all_discussions_are_resolved)
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddIndexToNoteDiscussionId < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :notes, :discussion_id
  end

  def down
    remove_index :notes, :discussion_id if index_exists? :notes, :discussion_id
  end
end

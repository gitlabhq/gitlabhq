# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDiscussionIdsToNotes < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notes, :discussion_id, :string
    add_column :notes, :original_discussion_id, :string
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ResetDiffNoteDiscussionIdBecauseItWasCalculatedWrongly < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute "UPDATE notes SET discussion_id = NULL WHERE discussion_id IS NOT NULL AND type = 'DiffNote'"
  end
end

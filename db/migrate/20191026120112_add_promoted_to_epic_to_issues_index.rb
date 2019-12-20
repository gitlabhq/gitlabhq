# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPromotedToEpicToIssuesIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :issues, :epics, column: :promoted_to_epic_id, on_delete: :nullify
    add_concurrent_index :issues, :promoted_to_epic_id, where: 'promoted_to_epic_id IS NOT NULL'
  end

  def down
    remove_concurrent_index(:issues, :promoted_to_epic_id)
    remove_foreign_key :issues, column: :promoted_to_epic_id
  end
end

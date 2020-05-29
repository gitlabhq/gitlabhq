# frozen_string_literal: true

class AddIssuesLastEditedByIdIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, :last_edited_by_id
    add_concurrent_index :epics, :last_edited_by_id
  end

  def down
    remove_concurrent_index :issues, :last_edited_by_id
    remove_concurrent_index :epics, :last_edited_by_id
  end
end

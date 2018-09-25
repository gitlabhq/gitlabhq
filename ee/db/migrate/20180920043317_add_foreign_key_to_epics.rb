# frozen_string_literal: true

class AddForeignKeyToEpics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :epics, :users, column: :closed_by_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :epics, column: :closed_by_id
  end
end

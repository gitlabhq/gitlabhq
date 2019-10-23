# frozen_string_literal: true

class AddSourcingEpicDatesFks < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :epics, :start_date_sourcing_epic_id, where: 'start_date_sourcing_epic_id is not null'
    add_concurrent_index :epics, :due_date_sourcing_epic_id, where: 'due_date_sourcing_epic_id is not null'

    add_concurrent_foreign_key :epics, :epics, column: :start_date_sourcing_epic_id, on_delete: :nullify
    add_concurrent_foreign_key :epics, :epics, column: :due_date_sourcing_epic_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :epics, column: :start_date_sourcing_epic_id
    remove_foreign_key_if_exists :epics, column: :due_date_sourcing_epic_id

    remove_concurrent_index :epics, :start_date_sourcing_epic_id
    remove_concurrent_index :epics, :due_date_sourcing_epic_id
  end
end

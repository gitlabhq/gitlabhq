# frozen_string_literal: true

class AddIndexToOncallShftsOnStartsAtAndEndsAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  NEW_NAME = 'index_oncall_shifts_on_rotation_id_and_starts_at_and_ends_at'
  OLD_NAME = 'index_incident_management_oncall_shifts_on_rotation_id'

  def up
    add_concurrent_index :incident_management_oncall_shifts, %i[rotation_id starts_at ends_at], name: NEW_NAME

    remove_concurrent_index_by_name :incident_management_oncall_shifts, OLD_NAME
  end

  def down
    add_concurrent_index :incident_management_oncall_shifts, :rotation_id, name: OLD_NAME

    remove_concurrent_index_by_name :incident_management_oncall_shifts, NEW_NAME
  end
end

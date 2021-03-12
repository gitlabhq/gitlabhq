# frozen_string_literal: true

class AddIterationsCadenceToSprints < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_sprints_iterations_cadence_id'

  def up
    add_column :sprints, :iterations_cadence_id, :integer unless column_exists?(:sprints, :iterations_cadence_id)

    add_concurrent_index :sprints, :iterations_cadence_id, name: INDEX_NAME
    add_concurrent_foreign_key :sprints, :iterations_cadences, column: :iterations_cadence_id, on_delete: :cascade
  end

  def down
    remove_column :sprints, :iterations_cadence_id if column_exists?(:sprints, :iterations_cadence_id)
  end
end

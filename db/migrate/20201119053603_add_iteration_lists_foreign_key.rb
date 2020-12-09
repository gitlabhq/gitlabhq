# frozen_string_literal: true

class AddIterationListsForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_lists_on_iteration_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :lists, :iteration_id, name: INDEX_NAME
    add_concurrent_foreign_key :lists, :sprints, column: :iteration_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :lists, :sprints, column: :iteration_id
    remove_concurrent_index_by_name :lists, INDEX_NAME
  end
end

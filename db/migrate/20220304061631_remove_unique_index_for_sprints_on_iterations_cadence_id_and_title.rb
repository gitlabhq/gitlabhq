# frozen_string_literal: true

class RemoveUniqueIndexForSprintsOnIterationsCadenceIdAndTitle < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_sprints_on_iterations_cadence_id_and_title'

  def up
    remove_concurrent_index_by_name :sprints, INDEX_NAME
  end

  def down
    add_concurrent_index :sprints, [:iterations_cadence_id, :title], name: INDEX_NAME, unique: true
  end
end

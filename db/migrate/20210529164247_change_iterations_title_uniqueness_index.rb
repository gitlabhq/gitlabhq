# frozen_string_literal: true

class ChangeIterationsTitleUniquenessIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_sprints_on_iterations_cadence_id_and_title'
  OLD_INDEX_NAME = 'index_sprints_on_group_id_and_title'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sprints, [:iterations_cadence_id, :title], name: INDEX_NAME, unique: true
    remove_concurrent_index_by_name :sprints, OLD_INDEX_NAME
  end

  def down
    # noop
    # rollback would not work as we can have duplicate records once the unique `index_sprints_on_group_id_and_title` index is removed
  end
end

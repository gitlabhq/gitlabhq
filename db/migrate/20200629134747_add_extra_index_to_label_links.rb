# frozen_string_literal: true

class AddExtraIndexToLabelLinks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_COVERING_ALL_COLUMNS = 'index_on_label_links_all_columns'
  INDEX_TO_REPLACE = 'index_label_links_on_label_id'
  NEW_INDEX = 'index_label_links_on_label_id_and_target_type'

  disable_ddl_transaction!

  def up
    add_concurrent_index :label_links, [:target_id, :label_id, :target_type], name: INDEX_COVERING_ALL_COLUMNS

    add_concurrent_index :label_links, [:label_id, :target_type], name: NEW_INDEX
    remove_concurrent_index_by_name(:label_links, INDEX_TO_REPLACE)
  end

  def down
    remove_concurrent_index_by_name(:label_links, INDEX_COVERING_ALL_COLUMNS)

    add_concurrent_index(:label_links, :label_id, name: INDEX_TO_REPLACE)
    remove_concurrent_index_by_name(:label_links, NEW_INDEX)
  end
end

# frozen_string_literal: true

class RemoveGroupIdTitleIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_labels_on_group_id_and_title_with_null_project_id'
  LABELS_TABLE = :labels

  def up
    remove_concurrent_index_by_name LABELS_TABLE, INDEX_NAME
  end

  def down
    add_concurrent_index LABELS_TABLE, [:group_id, :title], where: 'project_id IS NULL', name: INDEX_NAME
  end
end

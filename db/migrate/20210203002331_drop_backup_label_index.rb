# frozen_string_literal: true

class DropBackupLabelIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'backup_labels_project_id_title_idx'

  def up
    remove_concurrent_index_by_name(:backup_labels, name: INDEX_NAME)
  end

  def down
    add_concurrent_index :backup_labels, [:project_id, :title], name: INDEX_NAME, unique: true, where: 'group_id = NULL::integer'
  end
end

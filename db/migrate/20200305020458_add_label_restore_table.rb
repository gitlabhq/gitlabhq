# frozen_string_literal: true

class AddLabelRestoreTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # copy table
    execute "CREATE TABLE #{backup_labels_table_name} (LIKE #{labels_table_name} INCLUDING ALL);"

    # make the primary key a real functioning one rather than incremental
    execute "ALTER TABLE #{backup_labels_table_name} ALTER COLUMN ID DROP DEFAULT;"

    # add some fields that make changes trackable
    execute "ALTER TABLE #{backup_labels_table_name} ADD COLUMN restore_action INTEGER;"
    execute "ALTER TABLE #{backup_labels_table_name} ADD COLUMN new_title VARCHAR;"
  end

  def down
    drop_table backup_labels_table_name
  end

  private

  def labels_table_name
    :labels
  end

  def backup_labels_table_name
    :backup_labels
  end
end

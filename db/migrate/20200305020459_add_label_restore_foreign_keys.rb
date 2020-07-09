# frozen_string_literal: true

class AddLabelRestoreForeignKeys < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # create foreign keys
    connection.foreign_keys(labels_table_name).each do |fk|
      fk_options = fk.options
      add_concurrent_foreign_key(backup_labels_table_name, fk.to_table, name: fk.name, column: fk_options[:column])
    end
  end

  def down
    connection.foreign_keys(backup_labels_table_name).each do |fk|
      with_lock_retries do
        remove_foreign_key backup_labels_table_name, name: fk.name
      end
    end
  end

  private

  def labels_table_name
    :labels
  end

  def backup_labels_table_name
    :backup_labels
  end
end

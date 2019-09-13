# frozen_string_literal: true

class AddDuplicatedToToIssue < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :issues, :duplicated_to_id, :integer unless duplicated_to_id_exists?
    add_concurrent_foreign_key :issues, :issues, column: :duplicated_to_id, on_delete: :nullify
    add_concurrent_index :issues, :duplicated_to_id, where: 'duplicated_to_id IS NOT NULL'
  end

  def down
    remove_foreign_key_without_error(:issues, column: :duplicated_to_id)
    remove_concurrent_index(:issues, :duplicated_to_id)
    remove_column(:issues, :duplicated_to_id) if duplicated_to_id_exists?
  end

  private

  def duplicated_to_id_exists?
    column_exists?(:issues, :duplicated_to_id)
  end
end

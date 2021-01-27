# frozen_string_literal: true

class DropNamespacesPlanId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :namespaces, :plan_id
    end
  end

  def down
    unless column_exists?(:namespaces, :plan_id)
      with_lock_retries do
        add_column :namespaces, :plan_id, :integer # rubocop:disable Migration/AddColumnsToWideTables
      end
    end

    add_concurrent_index :namespaces, :plan_id
    add_concurrent_foreign_key :namespaces, :plans, column: :plan_id, on_delete: :nullify
  end
end

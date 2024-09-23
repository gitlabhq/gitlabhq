# frozen_string_literal: true

class DropComplianceChecksTable < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :compliance_checks, column: :namespace_id, reverse_lock_order: true
    end

    with_lock_retries do
      remove_foreign_key_if_exists :compliance_checks, column: :requirement_id
    end

    drop_table :compliance_checks if table_exists?(:compliance_checks)
  end

  def down
    create_table :compliance_checks do |t|
      t.timestamps_with_timezone null: false
      t.bigint :requirement_id, null: false
      t.bigint :namespace_id, null: false
      t.integer :check_name, null: false, limit: 2

      t.index :namespace_id
      t.index [:requirement_id, :check_name], unique: true, name: 'u_compliance_checks_for_requirement'
    end

    add_concurrent_foreign_key :compliance_checks, :namespaces, column: :namespace_id, reverse_lock_order: true

    add_concurrent_foreign_key :compliance_checks, :compliance_requirements, column: :requirement_id,
      on_delete: :cascade, reverse_lock_order: true
  end
end

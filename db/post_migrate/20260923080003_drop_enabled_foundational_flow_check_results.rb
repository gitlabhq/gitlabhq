# frozen_string_literal: true

class DropEnabledFoundationalFlowCheckResults < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  TABLE_NAME = :enabled_foundational_flow_check_results

  def up
    drop_table TABLE_NAME, if_exists: true
  end

  def down
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :organization_id, null: false
      t.bigint :enabled_foundational_flow_id, null: false
      t.column :check_id, :smallint, null: false
      t.column :status, :smallint, null: false
      t.text :message, limit: 4096
      t.timestamps_with_timezone null: false

      t.index :organization_id, name: 'idx_enabled_foundational_flow_check_results_on_organization'
      t.index [:enabled_foundational_flow_id, :check_id], unique: true,
        name: 'idx_enabled_foundational_flow_check_results_on_flow_and_check'
    end
  end
end

# frozen_string_literal: true

class CreateEnabledFoundationalFlowCheckResults < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    create_table :enabled_foundational_flow_check_results do |t|
      t.bigint :organization_id, null: false
      t.bigint :enabled_foundational_flow_id, null: false
      t.column :check_id, :smallint, null: false # check_id comes from a FixedModel and bigint is not required
      t.column :status, :smallint, null: false
      t.text :message, limit: 4096
      t.timestamps_with_timezone null: false
    end

    add_index :enabled_foundational_flow_check_results, [:organization_id],
      name: 'idx_enabled_foundational_flow_check_results_on_organization'
    add_index :enabled_foundational_flow_check_results, [:enabled_foundational_flow_id, :check_id], unique: true,
      name: 'idx_enabled_foundational_flow_check_results_on_flow_and_check'
  end

  def down
    drop_table :enabled_foundational_flow_check_results
  end
end

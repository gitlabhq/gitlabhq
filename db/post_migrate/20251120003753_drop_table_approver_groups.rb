# frozen_string_literal: true

class DropTableApproverGroups < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    drop_table :approver_groups, if_exists: true
  end

  def down
    create_table :approver_groups do |t|
      t.bigint :target_id, null: false
      t.string :target_type, null: false
      t.bigint :group_id, null: false

      # rubocop:disable Migration/Datetime -- Needs to match old table before removal
      t.datetime :created_at, precision: nil, null: true
      t.datetime :updated_at, precision: nil, null: true
      # rubocop:enable Migration/Datetime
    end

    add_index :approver_groups, :group_id,
      name: 'index_approver_groups_on_group_id'
    add_index :approver_groups, [:target_id, :target_type],
      name: 'index_approver_groups_on_target_id_and_target_type'
  end
end

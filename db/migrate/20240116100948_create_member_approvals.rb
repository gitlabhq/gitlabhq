# frozen_string_literal: true

class CreateMemberApprovals < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    create_table :member_approvals do |t|
      t.datetime_with_timezone :reviewed_at
      t.timestamps_with_timezone

      t.bigint :member_id, null: false
      t.bigint :member_namespace_id, null: false
      t.bigint :requested_by_id
      t.bigint :reviewed_by_id
      t.integer :new_access_level, null: false
      t.integer :old_access_level, null: false
      t.integer :status, null: false, default: 0, limit: 2
    end

    add_index :member_approvals, :requested_by_id, name: 'index_member_approval_on_requested_by_id'
    add_index :member_approvals, :reviewed_by_id, name: 'index_member_approval_on_reviewed_by_id'
    add_index :member_approvals, :member_id, name: 'index_member_approval_on_member_id'
    add_index :member_approvals, :member_namespace_id, name: 'index_member_approval_on_member_namespace_id'
  end
end

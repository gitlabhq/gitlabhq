# frozen_string_literal: true

class CreateSubscriptionUserAddOnAssignments < Gitlab::Database::Migration[2.1]
  UNIQUE_INDEX_NAME = 'uniq_idx_user_add_on_assignments_on_add_on_purchase_and_user'

  def change
    create_table :subscription_user_add_on_assignments do |t|
      t.bigint :add_on_purchase_id, null: false
      t.bigint :user_id, null: false

      t.timestamps_with_timezone null: false

      t.index [:add_on_purchase_id, :user_id], unique: true, name: UNIQUE_INDEX_NAME
      t.index :user_id
    end
  end
end

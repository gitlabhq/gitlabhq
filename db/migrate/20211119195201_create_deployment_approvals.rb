# frozen_string_literal: true

class CreateDeploymentApprovals < Gitlab::Database::Migration[1.0]
  def change
    create_table :deployment_approvals do |t|
      t.bigint :deployment_id, null: false
      t.bigint :user_id, null: false, index: true
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false
      t.index [:deployment_id, :user_id], unique: true
    end
  end
end

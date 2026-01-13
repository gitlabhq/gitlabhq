# frozen_string_literal: true

class CreateActivationMetrics < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def up
    create_table :activation_metrics do |t|
      t.timestamps_with_timezone null: false
      t.bigint :user_id, null: false
      t.bigint :namespace_id, null: true
      t.integer :metric, null: false, limit: 2 # ActiveRecord enum

      t.index [:user_id, :namespace_id, :metric],
        unique: true,
        name: 'unique_activation_metric_user_id_namespace_id_and_metric'
    end
  end

  def down
    drop_table :activation_metrics, if_exists: true
  end
end

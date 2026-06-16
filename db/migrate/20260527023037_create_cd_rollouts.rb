# frozen_string_literal: true

class CreateCdRollouts < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    create_table :cd_rollouts do |t|
      t.bigint :group_id, null: false
      t.bigint :version_set_id, null: false
      t.bigint :environment_id, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :started_at
      t.datetime_with_timezone :finished_at
      t.integer :state, null: false, default: 0, limit: 2

      t.index :group_id
      t.index :environment_id
      t.index [:version_set_id, :state]
    end
  end
end

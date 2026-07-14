# frozen_string_literal: true

class CreateCdRolloutTransitions < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  ROLLOUT_INDEX_NAME = 'index_cd_rollout_transitions_on_rollout_id_and_created_at'
  ORG_INDEX_NAME = 'index_cd_rollout_transitions_on_organization_id'

  def change
    create_table :cd_rollout_transitions do |t|
      t.bigint :organization_id, null: false
      t.bigint :rollout_id, null: false
      t.bigint :principal_id
      t.datetime_with_timezone :created_at, null: false
      t.integer :from_state, null: false, limit: 2
      t.integer :to_state, null: false, limit: 2
      t.text :event, null: false, limit: 72
      t.text :principal_type, null: false, limit: 255
      t.text :reason, limit: 2000
      t.text :triggered_by, limit: 255

      t.index [:rollout_id, :created_at], name: ROLLOUT_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
    end
  end
end

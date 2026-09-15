# frozen_string_literal: true

class CreateCdRolloutIncomingEvents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  UNIQUE_INDEX_NAME = 'index_cd_rollout_incoming_events_on_rollout_id_and_idem_key'
  ORG_INDEX_NAME = 'index_cd_rollout_incoming_events_on_organization_id'
  CREATED_AT_INDEX_NAME = 'index_cd_rollout_incoming_events_on_created_at'

  def up
    create_table :cd_rollout_incoming_events do |t|
      t.bigint :organization_id, null: false
      t.bigint :rollout_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :status, null: false, default: 0, limit: 2
      t.text :idempotency_key, null: false, limit: 255

      t.index [:rollout_id, :idempotency_key], unique: true, name: UNIQUE_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
      # Backs Cd::Rollouts::PruneIncomingEventsWorker's created_before scan.
      t.index :created_at, name: CREATED_AT_INDEX_NAME
    end
  end

  def down
    drop_table :cd_rollout_incoming_events
  end
end

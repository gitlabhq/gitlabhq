# frozen_string_literal: true

class CreateIamOutbox < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  ORGANIZATION_INDEX_NAME = 'index_iam_outbox_on_organization_id'
  L0_UNDELIVERED_INDEX_NAME = 'index_iam_outbox_l0_undelivered_lookup'
  L2_UNDELIVERED_INDEX_NAME = 'index_iam_outbox_l2_undelivered_lookup'

  def change
    create_table :iam_outbox do |t|
      t.references :organization,
        foreign_key: { on_delete: :cascade },
        index: { name: ORGANIZATION_INDEX_NAME },
        null: false
      t.bigint :entity_id, null: false
      t.datetime_with_timezone :l0_delivered_at
      t.datetime_with_timezone :l2_delivered_at
      t.timestamps_with_timezone null: false
      t.column :event_type, :smallint, null: false
      t.column :l0_attempts, :smallint, null: false, default: 0
      t.column :l2_attempts, :smallint, null: false, default: 0
      t.text :entity_type, limit: 255, null: false
      t.text :l0_last_error, limit: 4096
      t.text :l2_last_error, limit: 4096
      t.jsonb :payload, null: false, default: {}

      t.index [:entity_type, :entity_id, :event_type],
        where: 'l0_delivered_at IS NULL',
        name: L0_UNDELIVERED_INDEX_NAME
      t.index [:entity_type, :entity_id, :event_type],
        where: 'l2_delivered_at IS NULL',
        name: L2_UNDELIVERED_INDEX_NAME
    end
  end
end

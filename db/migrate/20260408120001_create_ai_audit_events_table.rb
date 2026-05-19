# frozen_string_literal: true

class CreateAiAuditEventsTable < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  OPTIONS = {
    primary_key: [:id, :created_at],
    options: 'PARTITION BY RANGE (created_at)',
    if_not_exists: true
  }.freeze

  def up
    create_table :ai_audit_events, **OPTIONS do |t|
      t.bigserial :id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.uuid :cloud_event_id, null: false
      t.bigint :author_id, null: false
      t.bigint :project_id
      t.bigint :namespace_id
      t.text :event_name, null: false, limit: 255
      t.inet :ip_address
      t.bigint :workflow_id
      t.text :details # rubocop:disable Migration/AddLimitToTextColumns -- JSON blob for full CloudEvent payload, no practical limit

      t.index [:cloud_event_id, :created_at],
        unique: true,
        name: 'idx_ai_audit_events_on_cloud_event_id_created_at_unique'
      t.index [:namespace_id, :created_at],
        order: { created_at: :desc },
        name: 'idx_ai_audit_events_on_namespace_id_created_at'
      t.index [:project_id, :created_at],
        order: { created_at: :desc },
        name: 'idx_ai_audit_events_on_project_id_created_at'
      t.index :workflow_id,
        name: 'idx_ai_audit_events_on_workflow_id'
    end
  end

  def down
    drop_table :ai_audit_events
  end
end

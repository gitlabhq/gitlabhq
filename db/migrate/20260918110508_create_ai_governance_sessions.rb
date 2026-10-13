# frozen_string_literal: true

class CreateAiGovernanceSessions < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  EXTERNAL_XID_INDEX_NAME = 'i_ai_governance_sessions_on_namespace_source_external_xid'
  KEYSET_INDEX_NAME = 'i_ai_governance_sessions_on_namespace_started_at_id'
  WORKFLOW_INDEX_NAME = 'i_ai_governance_sessions_on_namespace_workflow'
  SESSION_SOURCE_CONSTRAINT_NAME = 'check_ai_session_is_duo_or_external'

  def up
    create_table :ai_governance_sessions, if_not_exists: true do |t|
      t.bigint :namespace_id, null: false
      t.bigint :project_id
      t.bigint :user_id, null: false
      t.bigint :workflow_id
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :session_started_at, null: false
      t.datetime_with_timezone :session_finished_at
      t.integer :source, limit: 2, null: false, default: 0
      t.integer :status, limit: 2, null: false, default: 0
      t.text :external_xid, limit: 255
      t.text :agent_type, limit: 50
      t.text :flow_type, limit: 255

      t.index [:namespace_id, :source, :external_xid],
        unique: true, where: 'external_xid IS NOT NULL', name: EXTERNAL_XID_INDEX_NAME
      t.index [:namespace_id, :session_started_at, :id], name: KEYSET_INDEX_NAME
      # Scoped to namespace_id, the sharding key, per doc/development/cells/_index.md's rule
      # that a new unique index cannot rely on global uniqueness across cells.
      t.index [:namespace_id, :workflow_id],
        unique: true, where: 'workflow_id IS NOT NULL', name: WORKFLOW_INDEX_NAME
      t.index :project_id
      t.index :user_id

      t.check_constraint 'num_nonnulls(workflow_id, external_xid) = 1', name: SESSION_SOURCE_CONSTRAINT_NAME
    end
  end

  def down
    drop_table :ai_governance_sessions
  end
end

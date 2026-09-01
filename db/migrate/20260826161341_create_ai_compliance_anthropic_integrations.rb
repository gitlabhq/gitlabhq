# frozen_string_literal: true

class CreateAiComplianceAnthropicIntegrations < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  NAMESPACE_INDEX_NAME = 'index_ai_compliance_anthropic_integrations_on_namespace_id'

  def change
    create_table :ai_compliance_anthropic_integrations do |t|
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :consecutive_failure_count, null: false, default: 0, limit: 2
      t.integer :disabled_reason, limit: 2
      t.boolean :enabled, null: false, default: false
      t.jsonb :api_key, null: false
      t.text :anthropic_organization_uuid, limit: 255
      t.text :list_cursor, limit: 2048
      t.text :last_error, limit: 1024

      t.index :namespace_id, unique: true, name: NAMESPACE_INDEX_NAME
    end
  end
end

# frozen_string_literal: true

class CreateAgentActivityEvents < Gitlab::Database::Migration[1.0]
  def change
    create_table :agent_activity_events do |t|
      t.bigint :agent_id, null: false
      t.bigint :user_id, index: { where: 'user_id IS NOT NULL' }
      t.bigint :project_id, index: { where: 'project_id IS NOT NULL' }
      t.bigint :merge_request_id, index: { where: 'merge_request_id IS NOT NULL' }
      t.bigint :agent_token_id, index: { where: 'agent_token_id IS NOT NULL' }

      t.datetime_with_timezone :recorded_at, null: false
      t.integer :kind, limit: 2, null: false
      t.integer :level, limit: 2, null: false

      t.binary :sha
      t.text :detail, limit: 255

      t.index [:agent_id, :recorded_at, :id]
    end
  end
end

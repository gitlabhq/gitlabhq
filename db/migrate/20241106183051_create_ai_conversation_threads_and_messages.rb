# frozen_string_literal: true

class CreateAiConversationThreadsAndMessages < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    create_table :ai_conversation_threads do |t| # rubocop:disable Migration/EnsureFactoryForTable, Lint/RedundantCopDisableDirective -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigint :user_id, null: false
      t.bigint :organization_id, null: false
      t.datetime_with_timezone :last_updated_at, null: false, default: -> { 'NOW()' }
      t.timestamps_with_timezone null: false
      t.integer :conversation_type, limit: 2, null: false

      t.index :last_updated_at
      t.index :organization_id
      t.index [:user_id, :last_updated_at]
    end

    create_table :ai_conversation_messages do |t| # rubocop:disable Migration/EnsureFactoryForTable, Lint/RedundantCopDisableDirective -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigint :thread_id, null: false
      t.bigint :agent_version_id, null: true
      t.bigint :organization_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :role, limit: 2, null: false
      t.boolean :has_feedback, default: false
      t.jsonb :extras, default: {}, null: false
      t.jsonb :error_details, default: {}, null: false
      t.text :content, null: false, limit: 512.kilobytes
      t.text :request_xid, limit: 255
      t.text :message_xid, limit: 255
      t.text :referer_url, limit: 255

      t.index [:thread_id, :created_at]
      t.index :message_xid
      t.index :organization_id
      t.index :agent_version_id
    end
  end
end

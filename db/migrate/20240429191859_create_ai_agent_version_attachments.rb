# frozen_string_literal: true

class CreateAiAgentVersionAttachments < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  def up
    create_table :ai_agent_version_attachments do |t|
      t.timestamps_with_timezone null: false
      t.references :project, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.bigint :ai_agent_version_id, null: false, index: true
      t.bigint :ai_vectorizable_file_id, null: false, index: true
    end
  end

  def down
    drop_table :ai_agent_version_attachments
  end
end

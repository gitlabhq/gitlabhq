# frozen_string_literal: true

class DropAiAgentVersionAttachments < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  def up
    drop_table :ai_agent_version_attachments, if_exists: true
  end

  def down
    return if table_exists?(:ai_agent_version_attachments)

    create_table :ai_agent_version_attachments do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :ai_agent_version_id, null: false
      t.bigint :ai_vectorizable_file_id, null: false
    end

    add_concurrent_index :ai_agent_version_attachments, :ai_agent_version_id,
      name: :index_ai_agent_version_attachments_on_ai_agent_version_id

    add_concurrent_index :ai_agent_version_attachments, :ai_vectorizable_file_id,
      name: :index_ai_agent_version_attachments_on_ai_vectorizable_file_id

    add_concurrent_index :ai_agent_version_attachments, :project_id,
      name: :index_ai_agent_version_attachments_on_project_id

    add_concurrent_foreign_key :ai_agent_version_attachments, :ai_agent_versions,
      column: :ai_agent_version_id, on_delete: :cascade

    add_concurrent_foreign_key :ai_agent_version_attachments, :ai_vectorizable_files,
      column: :ai_vectorizable_file_id, on_delete: :cascade

    add_concurrent_foreign_key :ai_agent_version_attachments, :projects,
      column: :project_id, on_delete: :cascade, name: :fk_rails_a4ed49efb5
  end
end

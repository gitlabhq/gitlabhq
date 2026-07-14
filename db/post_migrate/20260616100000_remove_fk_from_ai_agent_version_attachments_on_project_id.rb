# frozen_string_literal: true

class RemoveFkFromAiAgentVersionAttachmentsOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :ai_agent_version_attachments
  FK_NAME = :fk_rails_a4ed49efb5

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects, column: :project_id, name: FK_NAME
    end
  end

  def down
    return unless table_exists?(TABLE_NAME)
    return unless table_exists?(:projects)

    add_concurrent_foreign_key TABLE_NAME, :projects,
      column: :project_id, on_delete: :cascade, name: FK_NAME
  end
end

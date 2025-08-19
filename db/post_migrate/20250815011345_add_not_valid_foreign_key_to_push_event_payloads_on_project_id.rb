# frozen_string_literal: true

class AddNotValidForeignKeyToPushEventPayloadsOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key(
      :push_event_payloads,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :push_event_payloads, column: :project_id
  end
end

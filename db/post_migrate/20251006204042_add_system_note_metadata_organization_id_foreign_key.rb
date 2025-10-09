# frozen_string_literal: true

class AddSystemNoteMetadataOrganizationIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_foreign_key :system_note_metadata,
      :organizations,
      column: :organization_id,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :system_note_metadata,
        column: :organization_id
      )
    end
  end
end

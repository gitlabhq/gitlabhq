# frozen_string_literal: true

class AddFkToResourceLinkEventsSystemNoteMetadataIdConvertToBigintForCom < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint # for the method `com_or_dev_or_test_but_not_jh?`

  disable_ddl_transaction!

  milestone '16.9'

  TABLE_NAME = :resource_link_events
  COLUMN = :system_note_metadata_id

  TARGET_TABLE_NAME = :system_note_metadata
  TARGET_COLUMN = :id_convert_to_bigint

  INDEX_NAME = 'index_system_note_metadata_pkey_on_id_convert_to_bigint'
  FK_NAME = 'fk_system_note_metadata_id_convert_to_bigint'

  def up
    return unless com_or_dev_or_test_but_not_jh?

    add_concurrent_index(TARGET_TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME)

    add_concurrent_foreign_key(
      TABLE_NAME,
      TARGET_TABLE_NAME,
      name: FK_NAME,
      column: COLUMN,
      target_column: TARGET_COLUMN,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    return unless com_or_dev_or_test_but_not_jh?

    with_lock_retries do
      remove_foreign_key_if_exists(
        TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end

    remove_concurrent_index_by_name(TARGET_TABLE_NAME, INDEX_NAME)
  end
end

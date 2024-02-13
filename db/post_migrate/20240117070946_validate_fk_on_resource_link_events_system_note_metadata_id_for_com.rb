# frozen_string_literal: true

class ValidateFkOnResourceLinkEventsSystemNoteMetadataIdForCom < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint # for the method `com_or_dev_or_test_but_not_jh?`

  milestone '16.9'

  TABLE_NAME = :resource_link_events
  COLUMN = :system_note_metadata_id
  FK_NAME = 'fk_system_note_metadata_id_convert_to_bigint'

  def up
    return unless com_or_dev_or_test_but_not_jh?

    prepare_async_foreign_key_validation TABLE_NAME, COLUMN, name: FK_NAME
  end

  def down
    return unless com_or_dev_or_test_but_not_jh?

    unprepare_async_foreign_key_validation TABLE_NAME, COLUMN, name: FK_NAME
  end
end

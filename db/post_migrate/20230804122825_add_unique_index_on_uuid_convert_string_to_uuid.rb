# frozen_string_literal: true

class AddUniqueIndexOnUuidConvertStringToUuid < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_vulnerability_occurrences_on_uuid_1"

  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    add_concurrent_index(
      :vulnerability_occurrences,
      :uuid_convert_string_to_uuid,
      unique: true,
      name: INDEX_NAME
    )
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name(
      :vulnerability_occurrences,
      INDEX_NAME
    )
  end
end

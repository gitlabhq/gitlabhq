# frozen_string_literal: true

class AsyncIndexForVulnerabilitiesUuidTypeMigration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = "tmp_idx_vulns_on_converted_uuid"
  WHERE_CLAUSE = "uuid_convert_string_to_uuid = '00000000-0000-0000-0000-000000000000'::uuid"

  def up
    prepare_async_index(
      :vulnerability_occurrences,
      %i[id uuid_convert_string_to_uuid],
      name: INDEX_NAME,
      where: WHERE_CLAUSE
    )
  end

  def down
    unprepare_async_index(
      :vulnerability_occurrences,
      %i[id uuid_convert_string_to_uuid],
      name: INDEX_NAME
    )
  end
end

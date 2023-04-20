# frozen_string_literal: true

class PrepareAsyncIndexForOverrideUuidsLogic < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_vulnerability_occurrences_for_override_uuids_logic'

  def up
    prepare_async_index :vulnerability_occurrences, [:project_id, :report_type, :location_fingerprint], name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :vulnerability_occurrences, INDEX_NAME
  end
end

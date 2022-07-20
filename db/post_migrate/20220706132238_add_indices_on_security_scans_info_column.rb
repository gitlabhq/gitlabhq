# frozen_string_literal: true

class AddIndicesOnSecurityScansInfoColumn < Gitlab::Database::Migration[2.0]
  INDEX_NAME_ON_ERRORS = :index_security_scans_on_length_of_errors
  INDEX_NAME_ON_WARNINGS = :index_security_scans_on_length_of_warnings

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :security_scans,
      "pipeline_id, jsonb_array_length(COALESCE((security_scans.info -> 'errors'::text), '[]'::jsonb))",
      name: INDEX_NAME_ON_ERRORS
    )

    add_concurrent_index(
      :security_scans,
      "pipeline_id, jsonb_array_length(COALESCE((security_scans.info -> 'warnings'::text), '[]'::jsonb))",
      name: INDEX_NAME_ON_WARNINGS
    )
  end

  def down
    remove_concurrent_index_by_name :security_scans, INDEX_NAME_ON_ERRORS
    remove_concurrent_index_by_name :security_scans, INDEX_NAME_ON_WARNINGS
  end
end

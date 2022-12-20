# frozen_string_literal: true

class DropIndexOnVulnerabilitiesStateCaseId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = "index_vulnerabilities_on_state_case_id"

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(
      :vulnerabilities,
      INDEX_NAME
    )
  end

  def down
    execute <<~SQL
      CREATE INDEX CONCURRENTLY index_vulnerabilities_on_state_case_id ON vulnerabilities
      USING btree (array_position(ARRAY[(1)::smallint, (4)::smallint, (3)::smallint, (2)::smallint], state), id DESC);
    SQL
  end
end

# frozen_string_literal: true
class AddTmpIndexOnReportType < Gitlab::Database::Migration[1.0]
  # Temporary index to perform migration fixing invalid vulnerability_occurrences.raw_metadata rows
  # Will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/349605
  INDEX_NAME = 'tmp_idx_vulnerability_occurrences_on_id_where_report_type_7_99'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerability_occurrences, :id, where: 'report_type IN (7, 99)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_occurrences, INDEX_NAME
  end
end

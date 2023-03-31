# frozen_string_literal: true

class RemoveTmpIndexVulnOccurrencesOnReportType < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'tmp_idx_vulnerability_occurrences_on_id_where_report_type_7_99'
  REPORT_TYPES = {
    cluster_image_scanning: 7,
    custom: 99
  }

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :vulnerability_occurrences, INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerability_occurrences, :id,
      where: "report_type IN (#{REPORT_TYPES.values.join(', ')})",
      name: INDEX_NAME
  end
end

# frozen_string_literal: true
class RemoveTmpIndexVulnsOnReportType < Gitlab::Database::Migration[2.0]
  # Temporary index to perform migration removing invalid vulnerabilities
  INDEX_NAME = 'tmp_idx_vulnerabilities_on_id_where_report_type_7_99'

  REPORT_TYPES = {
    cluster_image_scanning: 7,
    custom: 99
  }

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerabilities, :id,
      where: "report_type IN (#{REPORT_TYPES.values.join(', ')})",
      name: INDEX_NAME
  end
end

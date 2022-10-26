# frozen_string_literal: true

class AddIndexForCommonFinderQueryDescWithNamespaceId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_group_vulnerability_reads_common_finder_query_desc'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerability_reads,
                         [:namespace_id, :state, :report_type, :severity, :vulnerability_id],
                         name: INDEX_NAME,
                         order: { severity: :desc, vulnerability_id: :desc }
  end

  def down
    remove_concurrent_index_by_name :vulnerability_reads, INDEX_NAME
  end
end

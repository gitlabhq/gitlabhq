# frozen_string_literal: true

class IndexFindingIdForVulnerabilitiesSync < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_vulnerabilities_on_finding_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerabilities, :finding_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end
end

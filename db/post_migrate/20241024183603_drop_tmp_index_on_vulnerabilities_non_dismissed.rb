# frozen_string_literal: true

class DropTmpIndexOnVulnerabilitiesNonDismissed < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  TABLE_NAME = 'vulnerabilities'
  INDEX_NAME = 'tmp_index_on_vulnerabilities_non_dismissed'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, [:id], name: INDEX_NAME, where: 'state <> 2'
  end
end

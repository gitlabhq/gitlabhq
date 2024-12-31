# frozen_string_literal: true

class CreateIndexOnCveInPmAdvisories < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.8'

  INDEX_NAME = 'index_pm_advisories_on_cve'

  def up
    add_concurrent_index :pm_advisories, :cve, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :pm_advisories, INDEX_NAME
  end
end

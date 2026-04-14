# frozen_string_literal: true

class AddIndexOnPackageMetadataAdvisoryIdentifiers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  INDEX_NAME = 'index_pm_advisories_on_identifiers'

  def up
    add_concurrent_index :pm_advisories, :identifiers,
      using: :gin,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :pm_advisories, INDEX_NAME
  end
end

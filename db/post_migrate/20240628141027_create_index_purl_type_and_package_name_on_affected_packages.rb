# frozen_string_literal: true

class CreateIndexPurlTypeAndPackageNameOnAffectedPackages < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_pm_affected_packages_on_purl_type_and_package_name'
  disable_ddl_transaction!
  milestone '17.3'

  def up
    add_concurrent_index(:pm_affected_packages, [:purl_type, :package_name], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:pm_affected_packages, INDEX_NAME)
  end
end

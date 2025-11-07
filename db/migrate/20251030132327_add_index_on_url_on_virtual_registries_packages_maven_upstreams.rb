# frozen_string_literal: true

class AddIndexOnUrlOnVirtualRegistriesPackagesMavenUpstreams < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_virtual_registries_packages_maven_upstreams_on_url'

  def up
    add_concurrent_index :virtual_registries_packages_maven_upstreams, :url, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :virtual_registries_packages_maven_upstreams, INDEX_NAME
  end
end

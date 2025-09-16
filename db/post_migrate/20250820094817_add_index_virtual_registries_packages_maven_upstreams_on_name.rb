# frozen_string_literal: true

class AddIndexVirtualRegistriesPackagesMavenUpstreamsOnName < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  INDEX_NAME = 'virtual_registries_packages_maven_upstreams_on_name_trigram'

  def up
    add_concurrent_index :virtual_registries_packages_maven_upstreams, :name, name: INDEX_NAME,
      using: :gin, opclass: { name: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name :virtual_registries_packages_maven_upstreams, INDEX_NAME
  end
end

# frozen_string_literal: true

class AddIdxVirtualRegistriesPackagesMavenCachedResponsesRelativePathTrigram < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = 'idx_vreg_pkgs_maven_cached_responses_on_relative_path_trigram'

  def up
    add_concurrent_index :virtual_registries_packages_maven_cached_responses, :relative_path,
      using: :gin, opclass: :gin_trgm_ops, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :virtual_registries_packages_maven_cached_responses, INDEX_NAME
  end
end

# frozen_string_literal: true

class ChangeIndexVirtualRegistriesPackagesMavenCachedResponsesGroupId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  NEW_INDEX_NAME = :idx_vreg_pkgs_maven_cached_responses_on_group_id_status
  OLD_INDEX_NAME = :index_virtual_reg_pkgs_maven_cached_responses_on_group_id

  def up
    add_concurrent_index :virtual_registries_packages_maven_cached_responses, %i[group_id status], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :virtual_registries_packages_maven_cached_responses, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :virtual_registries_packages_maven_cached_responses, :group_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :virtual_registries_packages_maven_cached_responses, NEW_INDEX_NAME
  end
end

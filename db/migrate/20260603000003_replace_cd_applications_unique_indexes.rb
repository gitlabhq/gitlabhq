# frozen_string_literal: true

class ReplaceCdApplicationsUniqueIndexes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  OLD_INDEX_NAME = 'index_cd_applications_on_group_id_and_name'
  GROUP_INDEX_NAME = 'uniq_idx_cd_applications_on_group_id_and_name'
  ORGANIZATION_INDEX_NAME = 'uniq_idx_cd_applications_on_organization_id_and_name'

  def up
    add_concurrent_index :cd_applications, [:group_id, :name],
      unique: true,
      where: 'group_id IS NOT NULL',
      name: GROUP_INDEX_NAME

    add_concurrent_index :cd_applications, [:organization_id, :name],
      unique: true,
      where: 'organization_id IS NOT NULL',
      name: ORGANIZATION_INDEX_NAME

    remove_concurrent_index_by_name :cd_applications, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :cd_applications, [:group_id, :name], unique: true, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :cd_applications, GROUP_INDEX_NAME
    remove_concurrent_index_by_name :cd_applications, ORGANIZATION_INDEX_NAME
  end
end

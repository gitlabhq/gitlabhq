# frozen_string_literal: true

class AddUniqueIndexOnOrganizationLabelTitles < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_labels_on_organization_id_and_title_varchar_unique'

  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_concurrent_index :labels, [:organization_id, :title],
      name: INDEX_NAME,
      unique: true,
      where: 'organization_id IS NOT NULL',
      opclass: { title: :varchar_pattern_ops }
  end

  def down
    remove_concurrent_index_by_name :labels, INDEX_NAME
  end
end

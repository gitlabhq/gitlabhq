# frozen_string_literal: true

class RemoveOrganizationsPathWithoutCaseSensitivity < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  INDEX_NAME = 'unique_organizations_on_path'

  def up
    remove_concurrent_index_by_name :organizations, INDEX_NAME
  end

  def down
    add_concurrent_index :organizations, :path, unique: true, name: INDEX_NAME
  end
end

# frozen_string_literal: true

class AddOrganizationsPathUniqueWithCaseSensitivity < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  INDEX_NAME = 'unique_organizations_on_path_case_insensitive'

  def up
    add_concurrent_index :organizations, '(lower(path))', unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :organizations, INDEX_NAME
  end
end

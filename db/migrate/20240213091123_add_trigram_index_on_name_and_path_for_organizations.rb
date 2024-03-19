# frozen_string_literal: true

class AddTrigramIndexOnNameAndPathForOrganizations < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  TABLE_NAME = :organizations
  NAME_INDEX = 'index_organizations_on_name_trigram'
  PATH_INDEX = 'index_organizations_on_path_trigram'

  def up
    add_concurrent_index TABLE_NAME, :name, name: NAME_INDEX, using: :gin, opclass: { name: :gin_trgm_ops }
    add_concurrent_index TABLE_NAME, :path, name: PATH_INDEX, using: :gin, opclass: { path: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, NAME_INDEX
    remove_concurrent_index_by_name TABLE_NAME, PATH_INDEX
  end
end

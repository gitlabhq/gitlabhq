# frozen_string_literal: true

# rubocop:disable Migration/AddLimitToTextColumns, Migration/AddIndex
# limit is added in 20230515111314_add_text_limit_on_organization_name.rb
class AddNameToOrganization < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_organizations_on_name_lower'

  def up
    add_column :organizations, :name, :text, null: false, default: ''

    add_index :organizations, 'lower(name)', name: INDEX_NAME, unique: true
  end

  def down
    remove_column :organizations, :name, if_exists: true
  end
end
# rubocop:enable Migration/AddLimitToTextColumns, Migration/AddIndex

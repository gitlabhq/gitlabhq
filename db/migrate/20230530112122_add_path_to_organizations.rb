# frozen_string_literal: true

class AddPathToOrganizations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_organizations_on_path'

  def up
    # text limit is added in 20230530112602_add_text_limit_on_organization_path
    add_column :organizations, :path, :text, null: false, default: '', if_not_exists: true # rubocop:disable Migration/AddLimitToTextColumns

    add_concurrent_index :organizations, :path, name: INDEX_NAME, unique: true
  end

  def down
    remove_column :organizations, :path, if_exists: true
  end
end

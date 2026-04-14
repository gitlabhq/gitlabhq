# frozen_string_literal: true

class AddSiteNameToAdminAppearanceSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    add_column :appearances, :site_name, :text, null: true, if_not_exists: true
    add_text_limit :appearances, :site_name, 255
  end

  def down
    remove_column :appearances, :site_name, if_exists: true
  end
end

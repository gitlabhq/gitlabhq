# frozen_string_literal: true

class AddIdentifierColumnOnItem < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_column :ai_catalog_items, :identifier, :text, if_not_exists: true
    add_text_limit :ai_catalog_items, :identifier, 255
  end

  def down
    remove_column :ai_catalog_items, :identifier, :text
  end
end

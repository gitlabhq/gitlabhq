# frozen_string_literal: true

class DropNamespacesDescriptionColumns < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    remove_column :namespaces, :description, if_exists: true
    remove_column :namespaces, :description_html, if_exists: true
    remove_column :namespaces, :cached_markdown_version, if_exists: true
  end

  def down
    add_column :namespaces, :description, :string, default: '', null: false, if_not_exists: true
    add_column :namespaces, :description_html, :text, if_not_exists: true
    add_column :namespaces, :cached_markdown_version, :integer, if_not_exists: true
  end
end

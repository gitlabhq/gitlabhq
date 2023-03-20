# frozen_string_literal: true

class AddDesignDescription < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # text limit is added in a separate migration
  def up
    add_column :design_management_designs, :cached_markdown_version, :integer
    add_column :design_management_designs, :description, :text
    add_column :design_management_designs, :description_html, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :design_management_designs, :cached_markdown_version
    remove_column :design_management_designs, :description
    remove_column :design_management_designs, :description_html
  end
end

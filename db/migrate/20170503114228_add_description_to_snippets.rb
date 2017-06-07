class AddDescriptionToSnippets < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :snippets, :description, :text
    add_column :snippets, :description_html, :text
  end
end

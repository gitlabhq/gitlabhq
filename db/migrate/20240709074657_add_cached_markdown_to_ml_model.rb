# frozen_string_literal: true

class AddCachedMarkdownToMlModel < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  def up
    change_table :ml_models do |t|
      t.integer :cached_markdown_version, null: true
      t.text :description_html, null: true
    end

    add_text_limit :ml_models, :description_html, 50_000
  end

  def down
    remove_columns :ml_models, :cached_markdown_version, :description_html
  end
end

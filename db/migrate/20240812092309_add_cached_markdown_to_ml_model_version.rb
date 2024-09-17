# frozen_string_literal: true

class AddCachedMarkdownToMlModelVersion < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.4'

  def up
    change_table :ml_model_versions do |t|
      t.integer :cached_markdown_version, null: true, if_not_exists: true
      t.text :description_html, null: true, if_not_exists: true
    end

    add_text_limit :ml_model_versions, :description_html, 50_000
  end

  def down
    remove_columns :ml_model_versions, :cached_markdown_version, :description_html, if_exists: true
  end
end

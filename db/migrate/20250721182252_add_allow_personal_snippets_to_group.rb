# frozen_string_literal: true

class AddAllowPersonalSnippetsToGroup < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :namespace_settings, :allow_personal_snippets, :boolean, default: true, null: false
  end
end

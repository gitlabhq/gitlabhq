# frozen_string_literal: true

class AddLanguageIdToProgrammingLanguages < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :programming_languages, :language_id, :bigint, null: true, if_not_exists: true
  end
end

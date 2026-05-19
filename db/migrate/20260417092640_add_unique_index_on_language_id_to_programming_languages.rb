# frozen_string_literal: true

class AddUniqueIndexOnLanguageIdToProgrammingLanguages < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  def up
    add_concurrent_index :programming_languages, :language_id, unique: true,
      name: 'index_programming_languages_on_language_id'
  end

  def down
    remove_concurrent_index_by_name :programming_languages, 'index_programming_languages_on_language_id'
  end
end

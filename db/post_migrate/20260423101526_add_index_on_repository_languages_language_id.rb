# frozen_string_literal: true

class AddIndexOnRepositoryLanguagesLanguageId < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  def up
    add_concurrent_index :repository_languages, [:project_id, :language_id],
      unique: true,
      name: 'index_repository_languages_on_project_id_and_language_id'
  end

  def down
    remove_concurrent_index_by_name :repository_languages,
      'index_repository_languages_on_project_id_and_language_id'
  end
end

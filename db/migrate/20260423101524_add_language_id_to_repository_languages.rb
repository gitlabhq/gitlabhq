# frozen_string_literal: true

class AddLanguageIdToRepositoryLanguages < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :repository_languages, :language_id, :bigint, null: true, if_not_exists: true
  end
end

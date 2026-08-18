# frozen_string_literal: true

class AddTemporaryProgrammingLanguageIdIndexToRepositoryLanguages < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_repository_languages_on_programming_language_id'

  def up
    # Temporary index supporting the programming-language cleanup:
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/519895
    add_concurrent_index :repository_languages, :programming_language_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :repository_languages, INDEX_NAME
  end
end

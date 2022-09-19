# frozen_string_literal: true

class RemovePartialTrigramIndexesForIssues < Gitlab::Database::Migration[2.0]
  TITLE_INDEX_NAME = 'index_issues_on_title_trigram_non_latin'
  DESCRIPTION_INDEX_NAME = 'index_issues_on_description_trigram_non_latin'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :issues, TITLE_INDEX_NAME
    remove_concurrent_index_by_name :issues, DESCRIPTION_INDEX_NAME
  end

  def down
    add_concurrent_index :issues, :title,
      name: TITLE_INDEX_NAME,
      using: :gin, opclass: { description: :gin_trgm_ops },
      where: "title NOT SIMILAR TO '[\\u0000-\\u218F]*' OR description NOT SIMILAR TO '[\\u0000-\\u218F]*'"

    add_concurrent_index :issues, :description,
      name: DESCRIPTION_INDEX_NAME,
      using: :gin, opclass: { description: :gin_trgm_ops },
      where: "title NOT SIMILAR TO '[\\u0000-\\u218F]*' OR description NOT SIMILAR TO '[\\u0000-\\u218F]*'"
  end
end

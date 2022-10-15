# frozen_string_literal: true

class PreparePartialTrigramIndexesForIssuesAttempt2 < Gitlab::Database::Migration[2.0]
  TITLE_INDEX_NAME = 'index_issues_on_title_trigram_non_latin'
  DESCRIPTION_INDEX_NAME = 'index_issues_on_description_trigram_non_latin'

  def up
    prepare_async_index :issues, :title,
      name: TITLE_INDEX_NAME,
      using: :gin, opclass: { description: :gin_trgm_ops },
      where: "title NOT SIMILAR TO '[\\u0000-\\u02FF\\u1E00-\\u1EFF\\u2070-\\u218F]*' " \
             "OR description NOT SIMILAR TO '[\\u0000-\\u02FF\\u1E00-\\u1EFF\\u2070-\\u218F]*'"

    prepare_async_index :issues, :description,
      name: DESCRIPTION_INDEX_NAME,
      using: :gin, opclass: { description: :gin_trgm_ops },
      where: "title NOT SIMILAR TO '[\\u0000-\\u02FF\\u1E00-\\u1EFF\\u2070-\\u218F]*' " \
             "OR description NOT SIMILAR TO '[\\u0000-\\u02FF\\u1E00-\\u1EFF\\u2070-\\u218F]*'"
  end

  def down
    unprepare_async_index_by_name :issues, DESCRIPTION_INDEX_NAME
    unprepare_async_index_by_name :issues, TITLE_INDEX_NAME
  end
end

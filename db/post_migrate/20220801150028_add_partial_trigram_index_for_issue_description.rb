# frozen_string_literal: true

class AddPartialTrigramIndexForIssueDescription < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_description_trigram_non_latin'

  def up
    add_concurrent_index :issues, :description,
      name: INDEX_NAME,
      using: :gin, opclass: { description: :gin_trgm_ops },
      where: "title NOT SIMILAR TO '[\\u0000-\\u218F]*' OR description NOT SIMILAR TO '[\\u0000-\\u218F]*'"
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end

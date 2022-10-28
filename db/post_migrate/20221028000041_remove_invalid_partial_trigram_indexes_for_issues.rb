# frozen_string_literal: true

class RemoveInvalidPartialTrigramIndexesForIssues < Gitlab::Database::Migration[2.0]
  TITLE_INDEX_NAME = 'index_issues_on_title_trigram_non_latin'
  DESCRIPTION_INDEX_NAME = 'index_issues_on_description_trigram_non_latin'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :issues, TITLE_INDEX_NAME
    remove_concurrent_index_by_name :issues, DESCRIPTION_INDEX_NAME
  end

  def down; end
end

# frozen_string_literal: true

class PrepareRemovalOfIssueTrigramIndexes < Gitlab::Database::Migration[2.0]
  TITLE_INDEX_NAME = 'index_issues_on_title_trigram'
  DESCRIPTION_INDEX_NAME = 'index_issues_on_description_trigram'

  def up
    prepare_async_index_removal :issues, :title, name: TITLE_INDEX_NAME
    prepare_async_index_removal :issues, :description, name: DESCRIPTION_INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :issues, DESCRIPTION_INDEX_NAME
    unprepare_async_index_by_name :issues, TITLE_INDEX_NAME
  end
end

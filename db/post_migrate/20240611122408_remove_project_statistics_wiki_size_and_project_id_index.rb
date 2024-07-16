# frozen_string_literal: true

class RemoveProjectStatisticsWikiSizeAndProjectIdIndex < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  INDEX_NAME = 'index_project_statistics_on_wiki_size_and_project_id'
  COLUMNS = %i[wiki_size project_id]

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/466691
  def up
    return unless should_run?

    prepare_async_index_removal :project_statistics, COLUMNS, name: INDEX_NAME
  end

  def down
    return unless should_run?

    unprepare_async_index :project_statistics, COLUMNS, name: INDEX_NAME
  end

  def should_run?
    Gitlab.com_except_jh?
  end
end

# frozen_string_literal: true

class RemoveTmpIndexProjectStatisticsUpdatedAt < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  INDEX_NAME = 'tmp_index_project_statistics_updated_at'
  COLUMNS = %i[project_id updated_at]

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/464566
  def up
    prepare_async_index_removal :project_statistics, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :project_statistics, COLUMNS, where: "repository_size > 0", name: INDEX_NAME
  end
end

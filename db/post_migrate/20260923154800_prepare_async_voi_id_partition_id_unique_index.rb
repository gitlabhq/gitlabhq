# frozen_string_literal: true

class PrepareAsyncVoiIdPartitionIdUniqueIndex < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  TABLE_NAME = :vulnerability_occurrence_identifiers
  INDEX_NAME = 'index_vulnerability_occurrence_identifiers_on_id_partition_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/work_items/627927
  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/681
    prepare_async_index TABLE_NAME, %i[id partition_id], unique: true, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index TABLE_NAME, %i[id partition_id], name: INDEX_NAME
  end
end

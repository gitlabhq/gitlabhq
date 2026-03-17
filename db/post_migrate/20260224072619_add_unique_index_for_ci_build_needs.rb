# frozen_string_literal: true

class AddUniqueIndexForCiBuildNeeds < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  TABLE_NAME = :ci_build_needs
  PARTITIONING_PKEY_INDEX = :ci_build_needs_pkey_partitioning
  PARTITIONING_BUILD_INDEX = :index_ci_build_needs_on_build_id_and_name_partitioning

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/592
    prepare_async_index(TABLE_NAME, [:id, :partition_id], name: PARTITIONING_PKEY_INDEX, unique: true)
    prepare_async_index(TABLE_NAME, [:build_id, :name, :partition_id], name: PARTITIONING_BUILD_INDEX, unique: true)
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index_by_name(TABLE_NAME, PARTITIONING_PKEY_INDEX)
    unprepare_async_index_by_name(TABLE_NAME, PARTITIONING_BUILD_INDEX)
  end
end

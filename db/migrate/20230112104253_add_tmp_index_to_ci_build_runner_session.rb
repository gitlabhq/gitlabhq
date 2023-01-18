# frozen_string_literal: true

class AddTmpIndexToCiBuildRunnerSession < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = :tmp_index_ci_builds_runner_session_on_partition_id_and_id
  TABLE_NAME = :ci_builds_runner_session

  def up
    return unless Gitlab.com?

    add_concurrent_index(
      TABLE_NAME,
      [:partition_id, :id],
      where: 'partition_id = 101',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end

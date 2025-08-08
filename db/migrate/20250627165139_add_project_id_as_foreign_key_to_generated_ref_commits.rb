# frozen_string_literal: true

class AddProjectIdAsForeignKeyToGeneratedRefCommits < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.3'

  FK_NAME = 'fk_generated_ref_commits_project_id'
  TABLE_NAME = :p_generated_ref_commits
  def up
    add_concurrent_partitioned_foreign_key TABLE_NAME,
      :projects,
      column: :project_id,
      name: FK_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME,
        column: :project_id,
        name: FK_NAME
    end
  end
end

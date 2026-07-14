# frozen_string_literal: true

class RemoveFkFromCdArtifactSourcesOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_artifact_sources
  FK_NAME = :fk_71b7b33975

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects, column: :project_id, name: FK_NAME
    end
  end

  def down
    return unless table_exists?(TABLE_NAME)
    return unless table_exists?(:projects)

    add_concurrent_foreign_key TABLE_NAME, :projects,
      column: :project_id, on_delete: :restrict, name: FK_NAME
  end
end

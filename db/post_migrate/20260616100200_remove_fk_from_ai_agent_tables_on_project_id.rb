# frozen_string_literal: true

class RemoveFkFromAiAgentTablesOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  AGENTS_TABLE = :ai_agents
  AGENTS_FK_NAME = :fk_rails_3328b05449

  VERSIONS_TABLE = :ai_agent_versions
  VERSIONS_FK_NAME = :fk_rails_2205f8ca20

  def up
    if table_exists?(AGENTS_TABLE)
      with_lock_retries do
        remove_foreign_key_if_exists AGENTS_TABLE, :projects, column: :project_id, name: AGENTS_FK_NAME
      end
    end

    return unless table_exists?(VERSIONS_TABLE)

    with_lock_retries do
      remove_foreign_key_if_exists VERSIONS_TABLE, :projects, column: :project_id, name: VERSIONS_FK_NAME
    end
  end

  def down
    if table_exists?(AGENTS_TABLE) && table_exists?(:projects)
      add_concurrent_foreign_key AGENTS_TABLE, :projects,
        column: :project_id, on_delete: :cascade, name: AGENTS_FK_NAME
    end

    return unless table_exists?(VERSIONS_TABLE) && table_exists?(:projects)

    add_concurrent_foreign_key VERSIONS_TABLE, :projects,
      column: :project_id, on_delete: :cascade, name: VERSIONS_FK_NAME
  end
end

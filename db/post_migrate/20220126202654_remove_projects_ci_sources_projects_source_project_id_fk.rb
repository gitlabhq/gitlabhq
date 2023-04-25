# frozen_string_literal: true

class RemoveProjectsCiSourcesProjectsSourceProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_sources_projects, :projects, name: "fk_rails_64b6855cbc")

    with_lock_retries do
      execute('LOCK projects, ci_sources_projects IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_sources_projects, :projects, name: "fk_rails_64b6855cbc")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_sources_projects, :projects, name: "fk_rails_64b6855cbc", column: :source_project_id, target_column: :id, on_delete: :cascade)
  end
end

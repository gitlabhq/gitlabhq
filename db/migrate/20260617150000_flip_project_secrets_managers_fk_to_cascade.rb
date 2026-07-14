# frozen_string_literal: true

class FlipProjectSecretsManagersFkToCascade < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  FK_NAME = 'fk_8f88850d11'

  # Pre-deploy: flip `project_secrets_managers.project_id` -> `projects(id)`
  # from `ON DELETE SET NULL` to `ON DELETE CASCADE`. The same MR drops
  # the explicit `InitiateDeprovisionService` call from the project
  # destroy hook; once both land, parent destroy -> CASCADE deletes the
  # SM -> AFTER DELETE trigger inserts the deprovision maintenance task.
  # CASCADE has to be live before the new code deploys so the trigger
  # actually fires on parent destroy. See gitlab-org/gitlab#600290.
  #
  # Rolling-deploy window between pre-deploy and code deploy:
  #   - Old code calls `InitiateDeprovisionService` from the destroy hook,
  #     which still creates a task. The cascade-driven SM delete then
  #     fires the trigger; the trigger's `ON CONFLICT (project_id) DO
  #     NOTHING` sees the in-flight task and skips. One task per destroy.
  #
  # The drop and recreate run in a single transaction (the default
  # for regular migrations) so there is never a moment with no FK
  # constraint at all. `project_secrets_managers` is Open Beta and
  # small, so the immediate FK validation on recreate is cheap.
  def up
    remove_foreign_key_if_exists :project_secrets_managers, :projects, name: FK_NAME

    # rubocop:disable Migration/AddConcurrentForeignKey -- transactional drop+recreate is the point; table is Open Beta small
    add_foreign_key :project_secrets_managers, :projects,
      column: :project_id,
      on_delete: :cascade,
      name: FK_NAME
    # rubocop:enable Migration/AddConcurrentForeignKey
  end

  def down
    remove_foreign_key_if_exists :project_secrets_managers, :projects, name: FK_NAME

    # rubocop:disable Migration/AddConcurrentForeignKey -- transactional drop+recreate is the point; table is Open Beta small
    add_foreign_key :project_secrets_managers, :projects,
      column: :project_id,
      on_delete: :nullify,
      name: FK_NAME
    # rubocop:enable Migration/AddConcurrentForeignKey
  end
end

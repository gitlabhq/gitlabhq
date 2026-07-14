# frozen_string_literal: true

class AddNotNullToProjectSecretsManagersProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  # Runs after `CleanupLegacyProjectSecretsManagers` has removed every
  # row with a NULL `project_id`. Adds a validated CHECK NOT NULL
  # constraint, equivalent to a `SET NOT NULL` for read-side semantics
  # but cheaper to add online. See
  # https://gitlab.com/gitlab-org/gitlab/-/issues/600290.
  def up
    add_not_null_constraint :project_secrets_managers, :project_id
  end

  def down
    remove_not_null_constraint :project_secrets_managers, :project_id
  end
end

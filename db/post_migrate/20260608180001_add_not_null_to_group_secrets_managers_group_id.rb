# frozen_string_literal: true

class AddNotNullToGroupSecretsManagersGroupId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  # Runs after `CleanupLegacyGroupSecretsManagers` has removed every
  # row with a NULL `group_id`. Adds a validated CHECK NOT NULL
  # constraint, equivalent to a `SET NOT NULL` for read-side semantics
  # but cheaper to add online. See
  # https://gitlab.com/gitlab-org/gitlab/-/issues/600290.
  def up
    add_not_null_constraint :group_secrets_managers, :group_id
  end

  def down
    remove_not_null_constraint :group_secrets_managers, :group_id
  end
end

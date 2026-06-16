# frozen_string_literal: true

class AddDenormalizedIdsToGroupSecretsManagers < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  # Denormalize the ids the deprovision flow needs onto the SM row itself.
  # See gitlab-org/gitlab#600290 for the trigger-based design that consumes
  # these columns at SM-delete time. NOT NULL constraint comes in a
  # separate post-deploy migration once backfill is complete.
  def up
    add_column :group_secrets_managers, :organization_id, :bigint, if_not_exists: true
    add_column :group_secrets_managers, :root_namespace_id, :bigint, if_not_exists: true
  end

  def down
    remove_column :group_secrets_managers, :organization_id, if_exists: true
    remove_column :group_secrets_managers, :root_namespace_id, if_exists: true
  end
end

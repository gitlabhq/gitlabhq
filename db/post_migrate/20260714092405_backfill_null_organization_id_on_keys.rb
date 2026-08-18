# frozen_string_literal: true

class BackfillNullOrganizationIdOnKeys < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  BATCH_SIZE = 1_000
  # The default (root) organization. Hardcoded rather than loading the model.
  ORG_ID = 1

  # Backfill any remaining NULLs to the default (root) organization. On
  # GitLab.com all rows were already backfilled by the batched background
  # migrations (BackfillOrganizationIdKeys and BackfillOrganizationIdLdapKeys),
  # so this matches no rows there. On Self-Managed and Dedicated instances,
  # SSH keys with NULL user_id or a user_id pointing to a deleted user are
  # never backfilled by those BBMs (which join FROM users WHERE
  # keys.user_id = users.id). They must be backfilled before the NOT NULL
  # constraint is validated in the migration that follows.
  #
  # See: https://gitlab.com/gitlab-org/gitlab/-/issues/605197
  def up
    model = define_batchable_model(:keys)

    model.where(organization_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(organization_id: ORG_ID)
    end
  end

  def down
    # no-op: backfilled organization_id values are not reverted.
  end
end

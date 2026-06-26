# frozen_string_literal: true

class BackfillNullOrganizationIdOnOauthApplications < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 1_000
  # The default (root) organization. Hardcoded rather than loading the model.
  ORG_ID = 1

  # Backfill any remaining NULLs to the default (root) organization. On
  # gitlab.com all rows were already backfilled by the batched background
  # migration in 18.9, so this matches no rows there. On Dedicated and
  # self-managed instances, oauth_applications rows (e.g. GitLab Pages,
  # Mattermost) may be created via `gitlab-ctl reconfigure` or CNG's
  # custom-instance-setup without an organization_id. They must be backfilled
  # before the NOT NULL constraint is validated in the migration that follows.
  #
  # See: https://gitlab.com/gitlab-org/gitlab/-/work_items/600899
  def up
    model = define_batchable_model(:oauth_applications)

    model.where(organization_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(organization_id: ORG_ID)
    end
  end

  def down
    # no-op: backfilled organization_id values are not reverted.
  end
end

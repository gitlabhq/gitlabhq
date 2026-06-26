# frozen_string_literal: true

class AddNotNullConstraintToOauthApplicationsOrgId < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  # Reintroduces the NOT NULL constraint that the no-op'd
  # 20260417155126 migration originally added. NULL rows are backfilled by
  # 20260625131308_backfill_null_organization_id_on_oauth_applications.rb,
  # which runs first, so VALIDATE CONSTRAINT succeeds on all instance types.
  # Where the constraint already exists (e.g. gitlab.com, from 20260417155126),
  # add_not_null_constraint is a no-op.
  #
  # See: https://gitlab.com/gitlab-org/gitlab/-/work_items/600899
  def up
    add_not_null_constraint :oauth_applications, :organization_id
  end

  def down
    remove_not_null_constraint :oauth_applications, :organization_id
  end
end

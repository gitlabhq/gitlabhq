# frozen_string_literal: true

class AddNotNullConstraintToKeysOrgId < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  # Reintroduces the NOT NULL constraint that the no-op'd
  # 20260422180000 migration originally added. NULL rows are backfilled by
  # 20260714092405_backfill_null_organization_id_on_keys.rb,
  # which runs first, so VALIDATE CONSTRAINT succeeds on all instance types.
  # Where the constraint already exists (e.g. GitLab.com, from 20260422180000),
  # add_not_null_constraint is a no-op.
  #
  # See: https://gitlab.com/gitlab-org/gitlab/-/issues/605197
  def up
    add_not_null_constraint :keys, :organization_id
  end

  def down
    remove_not_null_constraint :keys, :organization_id
  end
end

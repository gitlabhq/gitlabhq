# frozen_string_literal: true

class AddNotNullConstraintToKeysOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  # No-op.
  #
  # This migration originally added a NOT NULL constraint to
  # keys.organization_id. It fails on Self-Managed and Dedicated instances
  # that still have NULL rows (SSH keys with NULL user_id or a user_id pointing
  # to a deleted user are never backfilled by the batched background migration).
  # We do not backdate migrations, so it cannot be fixed in place. The
  # backfill and the constraint were reintroduced as later migrations:
  #
  #   db/post_migrate/20260714092405_backfill_null_organization_id_on_keys.rb
  #   db/post_migrate/20260714092408_add_not_null_constraint_to_keys_org_id.rb
  #
  # See: https://gitlab.com/gitlab-org/gitlab/-/issues/605197
  def up; end

  def down; end
end

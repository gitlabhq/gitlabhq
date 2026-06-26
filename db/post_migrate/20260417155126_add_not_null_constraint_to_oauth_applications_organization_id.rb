# frozen_string_literal: true

class AddNotNullConstraintToOauthApplicationsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  # No-op.
  #
  # This migration originally added a NOT NULL constraint to
  # oauth_applications.organization_id. It failed on Dedicated and
  # self-managed instances that still had NULL rows, because no backfill ran
  # first. We do not backdate migrations, so it cannot be fixed in place. The
  # backfill and the constraint were reintroduced as later migrations:
  #
  #   db/post_migrate/20260625131308_backfill_null_organization_id_on_oauth_applications.rb
  #   db/post_migrate/20260625131309_add_not_null_constraint_to_oauth_applications_org_id.rb
  #
  # See: https://gitlab.com/gitlab-org/gitlab/-/work_items/600899
  def up; end

  def down; end
end

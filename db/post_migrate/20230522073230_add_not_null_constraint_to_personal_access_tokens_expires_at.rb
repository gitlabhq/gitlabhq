# frozen_string_literal: true

class AddNotNullConstraintToPersonalAccessTokensExpiresAt < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up; end

  # required because specs like
  # /spec/lib/gitlab/background_migration/backfill_admin_mode_scope_for_personal_access_tokens_spec.rb
  # run against old schemas, thus a DOWN migration counterpart to
  # /db/migrate/20231027084327_change_personal_access_tokens_remove_not_null_expires_at.rb#L15
  # is required to achieve the correct db schema for these specs
  def down
    remove_not_null_constraint :personal_access_tokens, :expires_at
  end
end

# frozen_string_literal: true

class CleanupMigrateCiTriggersTokenToTokenEncrypted < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    delete_batched_background_migration('EncryptCiTriggerToken', :ci_triggers, :id, [])
  end

  def down
    # NOOP
  end
end

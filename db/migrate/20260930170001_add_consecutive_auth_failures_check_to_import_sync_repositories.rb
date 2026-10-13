# frozen_string_literal: true

class AddConsecutiveAuthFailuresCheckToImportSyncRepositories < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  CONSTRAINT_NAME = 'chk_import_sync_repositories_auth_failures'

  def up
    add_check_constraint :import_sync_repositories,
      'consecutive_auth_failures >= 0',
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :import_sync_repositories, CONSTRAINT_NAME
  end
end

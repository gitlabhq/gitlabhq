# frozen_string_literal: true

class AddConsecutiveAuthFailuresToImportSyncRepositories < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :import_sync_repositories, :consecutive_auth_failures, :smallint, default: 0, null: false
  end
end

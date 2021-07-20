# frozen_string_literal: true

class AddForeignKeyForEnvironmentIdToEnvironments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    # `validate: false` option is passed here, because validating the existing rows fails by the orphaned deployments,
    # which will be cleaned up in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64588.
    # The validation runs for only new records or updates, so that we can at least
    # stop creating orphaned rows.
    add_concurrent_foreign_key :deployments, :environments, column: :environment_id, on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :deployments, :environments
    end
  end
end

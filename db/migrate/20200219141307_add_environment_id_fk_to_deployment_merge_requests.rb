# frozen_string_literal: true

class AddEnvironmentIdFkToDeploymentMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :deployment_merge_requests, :environments, column: :environment_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :deployment_merge_requests, column: :environment_id
  end
end

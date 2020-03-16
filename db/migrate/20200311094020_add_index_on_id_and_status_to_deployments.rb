# frozen_string_literal: true

class AddIndexOnIdAndStatusToDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:id, :status]
  end

  def down
    remove_concurrent_index :deployments, [:id, :status]
  end
end

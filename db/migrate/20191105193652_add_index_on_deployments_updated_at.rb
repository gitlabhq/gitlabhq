# frozen_string_literal: true

class AddIndexOnDeploymentsUpdatedAt < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_COLUMNS = [:project_id, :updated_at]

  disable_ddl_transaction!

  def up
    add_concurrent_index(:deployments, INDEX_COLUMNS)
  end

  def down
    remove_concurrent_index(:deployments, INDEX_COLUMNS)
  end
end

# frozen_string_literal: true

class ChangePagesDeploymentSizeToBigintCleanup < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_type_change :pages_deployments, :size
  end

  def down
    undo_cleanup_concurrent_column_type_change :pages_deployments, :size, :integer, limit: 4
  end
end

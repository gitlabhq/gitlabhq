# frozen_string_literal: true

class AddColumnsToSecurityScans < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :security_scans, :project_id, :bigint
      add_column :security_scans, :pipeline_id, :bigint
    end
  end

  def down
    with_lock_retries do
      remove_column :security_scans, :project_id, :bigint
      remove_column :security_scans, :pipeline_id, :bigint
    end
  end
end

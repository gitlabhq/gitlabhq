# frozen_string_literal: true

class AddPartialIndexOnImportFailuresRetryCount < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :import_failures, [:project_id, :correlation_id_value], where: 'retry_count = 0'
  end

  def down
    remove_concurrent_index :import_failures, [:project_id, :correlation_id_value]
  end
end

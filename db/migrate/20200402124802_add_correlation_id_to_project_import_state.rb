# frozen_string_literal: true

class AddCorrelationIdToProjectImportState < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_mirror_data, :correlation_id_value, :string, limit: 128
    end
  end

  def down
    with_lock_retries do
      remove_column :project_mirror_data, :correlation_id_value
    end
  end
end

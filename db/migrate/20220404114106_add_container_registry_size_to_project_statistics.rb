# frozen_string_literal: true

class AddContainerRegistrySizeToProjectStatistics < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_statistics, :container_registry_size, :bigint, default: 0, null: false
  end
end

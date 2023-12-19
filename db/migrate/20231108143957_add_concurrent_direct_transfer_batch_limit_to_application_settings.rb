# frozen_string_literal: true

class AddConcurrentDirectTransferBatchLimitToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column :application_settings, :bulk_import_concurrent_pipeline_batch_limit, :smallint, default: 25, null: false
  end
end

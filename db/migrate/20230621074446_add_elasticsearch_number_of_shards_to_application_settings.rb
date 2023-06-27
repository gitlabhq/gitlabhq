# frozen_string_literal: true

class AddElasticsearchNumberOfShardsToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :application_settings, :elasticsearch_worker_number_of_shards, :integer, null: false, default: 2
  end
end

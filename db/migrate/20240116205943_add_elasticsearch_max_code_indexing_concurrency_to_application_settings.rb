# frozen_string_literal: true

class AddElasticsearchMaxCodeIndexingConcurrencyToApplicationSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.9'

  def change
    add_column :application_settings,
      :elasticsearch_max_code_indexing_concurrency,
      :integer,
      default: 30,
      null: false,
      if_not_exists: true
  end
end

# frozen_string_literal: true

class RemoveElasticsearchSettingsFromApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    with_lock_retries do
      remove_column :application_settings, :elasticsearch_aws
      remove_column :application_settings, :elasticsearch_search
      remove_column :application_settings, :elasticsearch_indexing
      remove_column :application_settings, :elasticsearch_username
      remove_column :application_settings, :elasticsearch_aws_region
      remove_column :application_settings, :elasticsearch_aws_access_key
      remove_column :application_settings, :elasticsearch_limit_indexing
      remove_column :application_settings, :elasticsearch_pause_indexing
      remove_column :application_settings, :elasticsearch_requeue_workers
      remove_column :application_settings, :elasticsearch_max_bulk_size_mb
      remove_column :application_settings, :elasticsearch_retry_on_failure
      remove_column :application_settings, :elasticsearch_max_bulk_concurrency
      remove_column :application_settings, :elasticsearch_client_request_timeout
      remove_column :application_settings, :elasticsearch_worker_number_of_shards
      remove_column :application_settings, :elasticsearch_analyzers_smartcn_search
      remove_column :application_settings, :elasticsearch_analyzers_kuromoji_search
      remove_column :application_settings, :elasticsearch_analyzers_smartcn_enabled
      remove_column :application_settings, :elasticsearch_analyzers_kuromoji_enabled
      remove_column :application_settings, :elasticsearch_indexed_field_length_limit
      remove_column :application_settings, :elasticsearch_indexed_file_size_limit_kb
      remove_column :application_settings, :elasticsearch_max_code_indexing_concurrency
    end
  end

  def down
    with_lock_retries do
      add_column :application_settings, :elasticsearch_aws, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_search, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_indexing, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_username, :text
      add_column :application_settings, :elasticsearch_aws_region, 'character varying', default: 'us-east-1'
      add_column :application_settings, :elasticsearch_aws_access_key, 'character varying'
      add_column :application_settings, :elasticsearch_limit_indexing, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_pause_indexing, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_requeue_workers, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_max_bulk_size_mb, :smallint, default: 10, null: false
      add_column :application_settings, :elasticsearch_retry_on_failure, :integer, default: 0, null: false
      add_column :application_settings, :elasticsearch_max_bulk_concurrency, :smallint, default: 10, null: false
      add_column :application_settings, :elasticsearch_client_request_timeout, :integer, default: 0, null: false
      add_column :application_settings, :elasticsearch_worker_number_of_shards, :integer, default: 2, null: false
      add_column :application_settings, :elasticsearch_analyzers_smartcn_search, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_analyzers_kuromoji_search, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_analyzers_smartcn_enabled, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_analyzers_kuromoji_enabled, :boolean, default: false, null: false
      add_column :application_settings, :elasticsearch_indexed_field_length_limit, :integer, default: 0, null: false
      add_column :application_settings, :elasticsearch_indexed_file_size_limit_kb, :integer, default: 1024, null: false
      add_column :application_settings, :elasticsearch_max_code_indexing_concurrency, :integer, default: 30, null: false
    end

    add_check_constraint(:application_settings, 'char_length(elasticsearch_username) <= 255', 'check_e5024c8801')
  end
end

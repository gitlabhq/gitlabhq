# frozen_string_literal: true

class AddElasticsearchApplicationSettingsColumnsBack < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  def up
    with_lock_retries do
      add_column :application_settings, :elasticsearch_aws, :boolean, default: false, null: false, if_not_exists: true

      add_column :application_settings, :elasticsearch_search, :boolean, default: false, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_indexing, :boolean, default: false, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_username, :text, if_not_exists: true

      add_column :application_settings, :elasticsearch_aws_region, 'character varying', default: 'us-east-1',
        if_not_exists: true

      add_column :application_settings, :elasticsearch_aws_access_key, 'character varying', if_not_exists: true

      add_column :application_settings, :elasticsearch_limit_indexing, :boolean, default: false, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_pause_indexing, :boolean, default: false, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_requeue_workers, :boolean, default: false, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_max_bulk_size_mb, :smallint, default: 10, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_retry_on_failure, :integer, default: 0, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_max_bulk_concurrency, :smallint, default: 10, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_client_request_timeout, :integer, default: 0, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_worker_number_of_shards, :integer, default: 2, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_analyzers_smartcn_search, :boolean, default: false, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_analyzers_kuromoji_search, :boolean, default: false,
        null: false, if_not_exists: true

      add_column :application_settings, :elasticsearch_analyzers_smartcn_enabled, :boolean, default: false,
        null: false, if_not_exists: true

      add_column :application_settings, :elasticsearch_analyzers_kuromoji_enabled, :boolean, default: false,
        null: false, if_not_exists: true

      add_column :application_settings, :elasticsearch_indexed_field_length_limit, :integer, default: 0, null: false,
        if_not_exists: true

      add_column :application_settings, :elasticsearch_indexed_file_size_limit_kb, :integer, default: 1024,
        null: false, if_not_exists: true

      add_column :application_settings, :elasticsearch_max_code_indexing_concurrency, :integer, default: 30,
        null: false, if_not_exists: true
    end

    add_text_limit :application_settings, :elasticsearch_username, 255
  end

  def down
    # no-op
  end
end

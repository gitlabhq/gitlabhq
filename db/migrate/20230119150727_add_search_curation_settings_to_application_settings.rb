# frozen_string_literal: true

class AddSearchCurationSettingsToApplicationSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_column :application_settings, :search_max_shard_size_gb, :integer, default: 50, null: false
    add_column :application_settings, :search_max_docs_denominator, :integer, default: 5_000_000, null: false
    add_column :application_settings, :search_min_docs_before_rollover, :integer, default: 100_000, null: false
  end

  def down
    remove_column :application_settings, :search_max_shard_size_gb
    remove_column :application_settings, :search_max_docs_denominator
    remove_column :application_settings, :search_min_docs_before_rollover
  end
end

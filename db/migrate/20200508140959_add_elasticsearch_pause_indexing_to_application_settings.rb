# frozen_string_literal: true

class AddElasticsearchPauseIndexingToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :elasticsearch_pause_indexing, :boolean, default: false, null: false
    end
  end

  def down
    remove_column :application_settings, :elasticsearch_pause_indexing
  end
end

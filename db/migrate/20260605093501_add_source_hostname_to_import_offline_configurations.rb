# frozen_string_literal: true

class AddSourceHostnameToImportOfflineConfigurations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    with_lock_retries do
      add_column :import_offline_configurations, :source_hostname, :text, null: true, if_not_exists: true
    end

    add_text_limit :import_offline_configurations, :source_hostname, 255
  end

  def down
    with_lock_retries do
      remove_column :import_offline_configurations, :source_hostname, if_exists: true
    end
  end
end

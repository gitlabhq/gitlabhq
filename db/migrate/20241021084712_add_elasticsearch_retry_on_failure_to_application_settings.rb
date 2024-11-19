# frozen_string_literal: true

class AddElasticsearchRetryOnFailureToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :elasticsearch_retry_on_failure, :integer, if_not_exists: true,
        default: 0, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :elasticsearch_retry_on_failure, if_exists: true
    end
  end
end

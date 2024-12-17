# frozen_string_literal: true

class AddAmazonQToAiSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  def up
    with_lock_retries do
      add_column :ai_settings, :amazon_q_oauth_application_id, :bigint, if_not_exists: true
      add_column :ai_settings, :amazon_q_service_account_user_id, :bigint, if_not_exists: true
      add_column :ai_settings, :amazon_q_ready, :boolean, default: false, null: false, if_not_exists: true
      add_column :ai_settings, :amazon_q_role_arn, :text, if_not_exists: true
    end

    add_concurrent_index :ai_settings, :amazon_q_oauth_application_id
    add_concurrent_foreign_key :ai_settings,
      :oauth_applications,
      column: :amazon_q_oauth_application_id,
      on_delete: :nullify
    add_concurrent_index :ai_settings, :amazon_q_service_account_user_id
    add_concurrent_foreign_key :ai_settings,
      :users,
      column: :amazon_q_service_account_user_id,
      on_delete: :nullify

    add_text_limit :ai_settings, :amazon_q_role_arn, 2048
  end

  def down
    with_lock_retries do
      remove_column :ai_settings, :amazon_q_oauth_application_id, if_exists: true
      remove_column :ai_settings, :amazon_q_service_account_user_id, if_exists: true
      remove_column :ai_settings, :amazon_q_ready, if_exists: true
      remove_column :ai_settings, :amazon_q_role_arn, if_exists: true
    end
  end
end

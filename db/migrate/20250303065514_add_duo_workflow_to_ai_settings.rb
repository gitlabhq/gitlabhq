# frozen_string_literal: true

class AddDuoWorkflowToAiSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.11'

  def up
    with_lock_retries do
      add_column :ai_settings, :duo_workflow_service_account_user_id, :bigint, if_not_exists: true
      add_column :ai_settings, :duo_workflow_oauth_application_id, :bigint, if_not_exists: true
    end

    add_concurrent_index :ai_settings, :duo_workflow_service_account_user_id
    add_concurrent_foreign_key :ai_settings,
      :users,
      column: :duo_workflow_service_account_user_id,
      on_delete: :nullify
    add_concurrent_index :ai_settings, :duo_workflow_oauth_application_id
    add_concurrent_foreign_key :ai_settings,
      :oauth_applications,
      column: :duo_workflow_oauth_application_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_column :ai_settings, :duo_workflow_service_account_user_id, if_exists: true
      remove_column :ai_settings, :duo_workflow_oauth_application_id, if_exists: true
    end
  end
end

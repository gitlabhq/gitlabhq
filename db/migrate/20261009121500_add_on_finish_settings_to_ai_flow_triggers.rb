# frozen_string_literal: true

class AddOnFinishSettingsToAiFlowTriggers < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :ai_flow_triggers, :status_on_finish, :text, if_not_exists: true
      add_column :ai_flow_triggers, :ready_merge_requests_on_finish, :boolean,
        default: false, null: false, if_not_exists: true
    end

    # Validated in a post-deployment migration.
    add_text_limit :ai_flow_triggers, :status_on_finish, 255, validate: false
  end

  def down
    with_lock_retries do
      remove_column :ai_flow_triggers, :status_on_finish, if_exists: true
      remove_column :ai_flow_triggers, :ready_merge_requests_on_finish, if_exists: true
    end
  end
end

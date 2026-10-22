# frozen_string_literal: true

class AddVersionsToAiGovernanceSessions < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!
  milestone '19.6'

  def up
    with_lock_retries do
      add_column :ai_governance_sessions, :glab_version, :text, if_not_exists: true
      add_column :ai_governance_sessions, :agent_version, :text, if_not_exists: true
    end

    add_text_limit :ai_governance_sessions, :glab_version, 255
    add_text_limit :ai_governance_sessions, :agent_version, 255
  end

  def down
    remove_column :ai_governance_sessions, :glab_version, if_exists: true
    remove_column :ai_governance_sessions, :agent_version, if_exists: true
  end
end

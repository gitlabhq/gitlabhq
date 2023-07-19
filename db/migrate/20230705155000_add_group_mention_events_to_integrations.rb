# frozen_string_literal: true

class AddGroupMentionEventsToIntegrations < Gitlab::Database::Migration[2.1]
  def change
    add_column :integrations, :group_mention_events, :boolean, null: false, default: false
    add_column :integrations, :group_confidential_mention_events, :boolean, null: false, default: false
  end
end

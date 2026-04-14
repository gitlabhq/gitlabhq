# frozen_string_literal: true

class RemoveDuoAgentPlatformRequestCountFromNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    remove_column :namespace_settings, :duo_agent_platform_request_count, if_exists: true
  end

  def down
    add_column :namespace_settings, :duo_agent_platform_request_count, :integer,
      default: 0, null: false, if_not_exists: true
  end
end

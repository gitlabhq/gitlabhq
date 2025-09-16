# frozen_string_literal: true

class AddDuoRequestCounterToAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  def up
    add_column :ai_settings, :duo_agent_platform_request_count, :integer, default: 0, null: false, if_not_exists: true
  end

  def down
    remove_column :ai_settings, :duo_agent_platform_request_count, if_exists: true
  end
end

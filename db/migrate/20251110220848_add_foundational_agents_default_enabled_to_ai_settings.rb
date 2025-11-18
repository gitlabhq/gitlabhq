# frozen_string_literal: true

class AddFoundationalAgentsDefaultEnabledToAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_column :ai_settings, :foundational_agents_default_enabled, :boolean, default: true
  end

  def down
    remove_column :ai_settings, :foundational_agents_default_enabled
  end
end

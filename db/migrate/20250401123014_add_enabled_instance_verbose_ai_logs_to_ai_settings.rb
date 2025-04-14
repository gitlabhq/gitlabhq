# frozen_string_literal: true

class AddEnabledInstanceVerboseAiLogsToAiSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :ai_settings, :enabled_instance_verbose_ai_logs, :boolean, null: true
  end
end

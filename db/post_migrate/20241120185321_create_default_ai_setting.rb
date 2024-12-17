# frozen_string_literal: true

class CreateDefaultAiSetting < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ai_gateway_url = ENV["AI_GATEWAY_URL"]

    execute <<-SQL
      INSERT INTO ai_settings (ai_gateway_url)
      SELECT #{ai_gateway_url ? "'#{ai_gateway_url}'" : 'NULL'}
      WHERE NOT EXISTS (SELECT 1 FROM ai_settings);
    SQL
  end

  def down
    execute("DELETE FROM ai_settings WHERE singleton = true;")
  end
end

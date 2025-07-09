# frozen_string_literal: true

class UpdateComBackfillSyncCursors < ClickHouse::Migration
  INSERT_QUERY = <<~SQL
    INSERT INTO sync_cursors (primary_key_value, table_name, recorded_at) VALUES (%{value}, \'%{table}\', now64())
  SQL

  def up
    return unless Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks  -- migration is for .com only.

    %w[ai_code_suggestion_events ai_troubleshoot_job_events ai_duo_chat_events ai_usage_events].each do |table_name|
      value = last_id(table_name)
      execute format(INSERT_QUERY, table: table_name, value: value) if value
    end
  end

  def down
    # no-op
  end

  private

  def last_id(table)
    ApplicationRecord.connection.execute("SELECT MAX(id) as max_id FROM #{table}").first&.fetch('max_id', nil)
  end
end

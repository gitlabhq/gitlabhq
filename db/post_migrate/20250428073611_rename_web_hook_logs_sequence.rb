# frozen_string_literal: true

class RenameWebHookLogsSequence < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def up
    connection.execute(<<~SQL)
      ALTER SEQUENCE web_hook_logs_id_seq RENAME TO web_hook_logs_daily_id_seq;
      ALTER SEQUENCE web_hook_logs_daily_id_seq OWNED BY web_hook_logs_daily.id;
    SQL
  end

  def down
    connection.execute(<<~SQL)
      ALTER SEQUENCE web_hook_logs_daily_id_seq RENAME TO web_hook_logs_id_seq;
      ALTER SEQUENCE web_hook_logs_id_seq OWNED BY web_hook_logs.id;
    SQL
  end
end

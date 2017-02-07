class RemoveInactiveDefaultEmailServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::Database::ThreadedConnectionPool.with_pool(2) do |pool|
      pool.execute_async <<-SQL.strip_heredoc
        DELETE FROM services
          WHERE type = 'BuildsEmailService'
            AND active IS FALSE
            AND properties = '{"notify_only_broken_builds":true}';
      SQL

      pool.execute_async <<-SQL.strip_heredoc
        DELETE FROM services
          WHERE type = 'PipelinesEmailService'
            AND active IS FALSE
            AND properties = '{"notify_only_broken_pipelines":true}';
      SQL
    end
  end

  def down
    # Nothing can be done to restore the records
  end
end

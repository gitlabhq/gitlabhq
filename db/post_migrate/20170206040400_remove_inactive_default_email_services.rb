class RemoveInactiveDefaultEmailServices < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::Database.with_connection_pool(2) do |pool|
      threads = []

      threads << Thread.new do
        pool.with_connection do |connection|
          connection.execute <<-SQL.strip_heredoc
          DELETE FROM services
            WHERE type = 'BuildsEmailService'
              AND active IS FALSE
              AND properties = '{"notify_only_broken_builds":true}';
          SQL
        end
      end

      threads << Thread.new do
        pool.with_connection do |connection|
          connection.execute <<-SQL.strip_heredoc
          DELETE FROM services
            WHERE type = 'PipelinesEmailService'
              AND active IS FALSE
              AND properties = '{"notify_only_broken_pipelines":true}';
          SQL
        end
      end

      threads.each(&:join)
    end
  end

  def down
    # Nothing can be done to restore the records
  end
end

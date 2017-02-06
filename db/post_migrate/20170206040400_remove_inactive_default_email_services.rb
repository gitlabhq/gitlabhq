class RemoveInactiveDefaultEmailServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    builds_service = spawn <<-SQL.strip_heredoc
      DELETE FROM services
        WHERE type = 'BuildsEmailService'
          AND active IS FALSE
          AND properties = '{"notify_only_broken_builds":true}';
    SQL

    pipelines_service = spawn <<-SQL.strip_heredoc
      DELETE FROM services
        WHERE type = 'PipelinesEmailService'
          AND active IS FALSE
          AND properties = '{"notify_only_broken_pipelines":true}';
    SQL

    [builds_service, pipelines_service].each(&:join)
  end

  private

  def spawn(query)
    Thread.new do
      with_connection do |connection|
        connection.execute(query)
      end
    end
  end

  def with_connection(&block)
    pool = ActiveRecord::Base.establish_connection
    pool.with_connection(&block)
  ensure
    pool.disconnect!
  end
end

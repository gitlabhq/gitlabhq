class RemoveInactiveDefaultEmailServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    builds_service = spawn <<-SQL.strip_heredoc
      DELETE FROM services
        WHERE type = 'BuildsEmailService'
          AND active = #{false_value}
          AND properties = '{"notify_only_broken_builds":true}';
    SQL

    pipelines_service = spawn <<-SQL.strip_heredoc
      DELETE FROM services
        WHERE type = 'PipelinesEmailService'
          AND active = #{false_value}
          AND properties = '{"notify_only_broken_pipelines":true}';
    SQL

    [builds_service, pipelines_service].each(&:join)
  end

  private

  def spawn(query)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.connection.execute(query)
      end
    end
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end

  def false_value
    quote(false)
  end
end

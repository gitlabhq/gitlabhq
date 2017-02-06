class RemoveInactiveDefaultEmailServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute <<-SQL.strip_heredoc
      DELETE FROM services
        WHERE type = 'BuildsEmailService'
          AND active = #{false_value}
          AND properties = '{"notify_only_broken_builds":true}';

      DELETE FROM services
        WHERE type = 'PipelinesEmailService'
          AND active = #{false_value}
          AND properties = '{"notify_only_broken_pipelines":true}';
    SQL
  end

  def false_value
    quote(false)
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end

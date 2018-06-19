class MigrateBuildEventsToPipelineEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    Gitlab::Database.with_connection_pool(2) do |pool|
      threads = []

      threads << Thread.new do
        pool.with_connection do |connection|
          Thread.current[:foreign_key_connection] = connection

          execute(<<-SQL.strip_heredoc)
            UPDATE services
              SET properties = replace(properties,
                                       'notify_only_broken_builds',
                                       'notify_only_broken_pipelines')
                , pipeline_events = #{true_value}
                , build_events = #{false_value}
            WHERE type IN
              ('SlackService', 'MattermostService', 'HipchatService')
              AND build_events = #{true_value};
          SQL
        end
      end

      threads << Thread.new do
        pool.with_connection do |connection|
          Thread.current[:foreign_key_connection] = connection

          execute(update_pipeline_services_sql)
        end
      end

      threads.each(&:join)
    end
  end

  def down
    # Don't bother to migrate the data back
  end

  def connection
    # Rails memoizes connection objects, but this causes them to be shared
    # amongst threads; we don't want that.
    Thread.current[:foreign_key_connection] || ApplicationRecord.connection
  end

  private

  def update_pipeline_services_sql
    if Gitlab::Database.postgresql?
      <<-SQL
        UPDATE services
          SET type = 'PipelinesEmailService'
            , properties = replace(properties,
                                   'notify_only_broken_builds',
                                   'notify_only_broken_pipelines')
            , pipeline_events = #{true_value}
            , build_events = #{false_value}
        WHERE type = 'BuildsEmailService'
        AND
          (SELECT 1 FROM services pipeline_services
             WHERE pipeline_services.project_id = services.project_id
               AND pipeline_services.type = 'PipelinesEmailService' LIMIT 1)
          IS NULL;
      SQL
    else
      <<-SQL
        UPDATE services build_services
         LEFT OUTER JOIN services pipeline_services
           ON build_services.project_id = pipeline_services.project_id
          AND pipeline_services.type = 'PipelinesEmailService'
          SET build_services.type = 'PipelinesEmailService'
            , build_services.properties = replace(build_services.properties,
                                         'notify_only_broken_builds',
                                         'notify_only_broken_pipelines')
            , build_services.pipeline_events = #{true_value}
            , build_services.build_events = #{false_value}
        WHERE build_services.type = 'BuildsEmailService'
          AND pipeline_services.id IS NULL;
      SQL
    end.strip_heredoc
  end
end

# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        class QueryDetails < MigrationObserver
          def before
            file_path = File.join(output_dir, "query-details.json")
            @file = File.open(file_path, 'wb')
            @writer = Oj::StreamWriter.new(@file, {})
            @writer.push_array
            @subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
              record_sql_event(*args)
            end
          end

          def after
            ActiveSupport::Notifications.unsubscribe(@subscriber)
            @writer.pop_all
            @writer.flush
            @file.close
          end

          def record
            # no-op
          end

          def record_sql_event(_name, started, finished, _unique_id, payload)
            @writer.push_value({
                                 start_time: started.iso8601(6),
                                 end_time: finished.iso8601(6),
                                 sql: payload[:sql],
                                 binds: payload[:type_casted_binds]
                               })
          end
        end
      end
    end
  end
end

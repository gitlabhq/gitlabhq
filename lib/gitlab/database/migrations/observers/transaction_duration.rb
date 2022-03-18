# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        class TransactionDuration < MigrationObserver
          def before
            file_path = File.join(output_dir, "transaction-duration.json")
            @file = File.open(file_path, 'wb')
            @writer = Oj::StreamWriter.new(@file, {})
            @writer.push_array
            @subscriber = ActiveSupport::Notifications.subscribe('transaction.active_record') do |*args|
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
            return if payload[:transaction_type] == :fake_transaction

            @writer.push_value({
                                 start_time: started.iso8601(6),
                                 end_time: finished.iso8601(6),
                                 transaction_type: payload[:transaction_type]
                               })
          end
        end
      end
    end
  end
end

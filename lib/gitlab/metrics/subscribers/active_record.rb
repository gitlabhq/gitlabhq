module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking raw SQL queries.
      #
      # Queries are obfuscated before being logged to ensure no private data is
      # exposed via InfluxDB/Grafana.
      class ActiveRecord < ActiveSupport::Subscriber
        attach_to :active_record

        SERIES = 'sql_queries'

        def sql(event)
          return unless current_transaction

          sql    = ObfuscatedSQL.new(event.payload[:sql]).to_s
          values = values_for(event)

          current_transaction.add_metric(SERIES, values, sql: sql)
        end

        private

        def values_for(event)
          values = { duration: event.duration }

          file, line = Metrics.last_relative_application_frame

          if file and line
            values[:file] = file
            values[:line] = line
          end

          values
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end

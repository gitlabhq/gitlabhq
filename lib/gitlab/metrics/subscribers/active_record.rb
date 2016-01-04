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

          values = values_for(event)
          tags   = tags_for(event)

          current_transaction.add_metric(SERIES, values, tags)
        end

        private

        def values_for(event)
          { duration: event.duration }
        end

        def tags_for(event)
          sql  = ObfuscatedSQL.new(event.payload[:sql]).to_s
          tags = { sql: sql }

          file, line = Metrics.last_relative_application_frame

          if file and line
            tags[:file] = file
            tags[:line] = line
          end

          tags
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Database
    module Sos
      class BaseDbStatsHandler
        attr_reader :connection, :name, :output

        def initialize(connection, name, output)
          @connection = connection
          @name = name
          @output = output
        end

        def execute_query(query)
          connection.execute(query)
        rescue StandardError => e
          Gitlab::AppLogger.error("Error executing on DB:#{name} query:#{query} error message:#{e.message}")
          []
        end

        def write_to_csv(query_name, result, include_timestamp: false)
          timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")

          file_path = if include_timestamp
                        File.join(name, query_name.to_s, "#{timestamp}.csv")
                      else
                        File.join(name, "#{query_name}.csv")
                      end

          output.write_file(file_path) do |f|
            CSV.open(f, "w+") do |csv|
              csv << result.fields
              result.each { |row| csv << row.values }
            end
          end
        rescue StandardError => e
          Gitlab::AppLogger.error("Error writing CSV for DB:#{name} query:#{query_name} error_message:#{e.message}")
        end
      end
    end
  end
end

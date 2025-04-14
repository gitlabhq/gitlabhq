# frozen_string_literal: true

module Gitlab
  module Database
    module Sos
      class PlatformConfigInfo < BaseDbStatsHandler
        attr_reader :connection, :name, :output

        QUERY = <<~SQL
         SELECT name AS key,
         setting AS value
        FROM pg_settings
        WHERE name IN ('server_version', 'data_directory', 'rds.extensions',
          'cloudsql.iam_authentication', 'azure.extensions')
        OR name LIKE 'alloydb%'
        UNION ALL
        SELECT 'System information', version();
        SQL

        def run
          query_results = execute_query(QUERY)

          config_info = connection.pool.db_config.configuration_hash.except(:username, :password)

          file_path = File.join(name, "platform_config_info.csv")

          output.write_file(file_path) do |f|
            CSV.open(f, "w+") do |csv|
              csv << %w[source key value]

              query_results.each do |row|
                csv << ['database', row['key'], row['value']]
              end

              config_info.each do |key, value|
                csv << ['config', key.to_s, value.to_s]
              end
            end
          end
        rescue StandardError => e
          Gitlab::AppLogger.error("Error writing platform config info for DB:#{name} with error message:#{e.message}")
        end
      end
    end
  end
end

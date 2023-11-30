# frozen_string_literal: true

require_relative 'base'

class Database
  class QueryAnalyzers
    class MultiplePartitionScanDetector < Database::QueryAnalyzers::Base
      def analyze(query)
        super

        return if config['todos']&.include?(query['fingerprint'])

        config['tables'].each do |table_name|
          if query['query'].include?(table_name) && query['plan'].to_s.include?('"Subplans Removed"=>0')
            (output[table_name] ||= []) << query
          end
        end
      end

      def save!
        config['tables'].each do |table_name|
          next unless output[table_name]

          Zlib::GzipWriter.open(output_path("#{table_name}_multiple_partition_scans.ndjson")) do |file|
            output[table_name].each do |query|
              file.puts(JSON.generate(query))
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'base'

class Database
  class QueryAnalyzers
    class MultiplePartitionScanDetector < Database::QueryAnalyzers::Base
      TABLES = %w[
        p_ci_builds p_ci_builds_metadata p_ci_job_annotations p_ci_runner_machine_builds
      ].freeze

      def analyze(query)
        super

        TABLES.each do |table_name|
          if query['query'].include?(table_name) && query['plan'].to_s.include?('"Subplans Removed"=>0')
            (output[table_name] ||= []) << query
          end
        end
      end

      def save!
        TABLES.each do |table_name|
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

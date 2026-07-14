# frozen_string_literal: true

require_relative 'base'

module Database
  class QueryAnalyzers
    class MultiplePartitionScanDetector < Database::QueryAnalyzers::Base
      P_CI_TABLE_REGEX = /\bp_ci_\w+/

      def analyze(query)
        super

        return if allowlisted?(query['fingerprint'])

        # "Subplans Removed"=>0 only appears for a partitioned scan that pruned nothing
        return unless query['plan'].to_s.include?('"Subplans Removed"=>0')

        query['query'].scan(P_CI_TABLE_REGEX).uniq.each do |table_name|
          (output[table_name] ||= []) << query
        end
      end

      def save!
        output.each do |table_name, queries|
          Zlib::GzipWriter.open(output_path("#{table_name}_multiple_partition_scans.ndjson")) do |file|
            queries.each do |query|
              file.puts(JSON.generate(query))
            end
          end
        end
      end

      private

      def allowlisted?(fingerprint)
        allowlisted_fingerprints.include?(fingerprint)
      end

      def allowlisted_fingerprints
        @allowlisted_fingerprints ||= [config['todos'], config['allowed']].flatten.compact.map do |entry|
          fingerprint = entry.is_a?(Hash) ? entry['fingerprint'] : entry

          if fingerprint.to_s.empty?
            raise ArgumentError,
              "#{self.class.name}: allowlist entry is missing a 'fingerprint' value: #{entry.inspect}"
          end

          fingerprint
        end
      end
    end
  end
end

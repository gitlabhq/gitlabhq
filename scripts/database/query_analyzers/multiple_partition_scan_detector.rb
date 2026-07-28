# frozen_string_literal: true

require_relative 'base'

module Database
  class QueryAnalyzers
    class MultiplePartitionScanDetector < Database::QueryAnalyzers::Base
      P_CI_TABLE_REGEX = /\bp_ci_\w+/

      # `Gitlab::Database::TablesTruncate#needs_truncation?` probes each candidate table
      # with a UNION of bare `SELECT EXISTS(SELECT * FROM <table>)` branches. Its fingerprint
      # churns as tables are added/dropped, so we can't just allowlist it.
      TABLE_EXISTENCE_PROBE_REGEX = /SELECT\s+EXISTS\s*\(\s*SELECT\s+\*\s+FROM\s+(?:"?\w+"?\.)?"?\w+"?\s*\)/i

      # `DatabaseCleanerDeletionBatchPatch` (spec/support/db_cleaner.rb) batches suite cleanup
      # into a single `execute` of bare `DELETE FROM <table>;` statements. Full-table cleanup
      # must touch every partition, and the table list (and so the fingerprint) churns as
      # tables are added/dropped, so we can't just allowlist it.
      DELETION_SWEEP_REGEX = /DELETE\s+FROM\s+(?:"?\w+"?\.)?"?\w+"?\s*;/i

      def analyze(query)
        super

        return if allowlisted?(query['fingerprint'])
        return if table_existence_sweep?(query['query'])
        return if deletion_sweep?(query['query'])

        # "Subplans Removed"=>0 only appears for a partitioned scan that pruned nothing.
        # This isn't a guaranteed signal for _all_ unpruned queries, so it may miss some.
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

      def table_existence_sweep?(query)
        query.to_s.scan(TABLE_EXISTENCE_PROBE_REGEX).size > 1
      end

      def deletion_sweep?(query)
        query.to_s.scan(DELETION_SWEEP_REGEX).size > 1
      end

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

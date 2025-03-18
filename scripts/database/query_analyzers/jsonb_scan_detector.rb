# frozen_string_literal: true

require_relative 'base'

module Database
  class QueryAnalyzers
    class JSONBScanDetector < Database::QueryAnalyzers::Base
      JSONB_MATCH_OPERATOR_EXPRESSION = /<@|@>/

      def initialize(*args)
        super
        output[:bad_queries] = []
      end

      def analyze(query)
        super
        return if config['todos']&.include?(query['fingerprint'])

        output[:bad_queries] << query if has_operator_in_where?(query['query'])
      end

      def save!
        return if output[:bad_queries].empty?

        Zlib::GzipWriter.open(output_path("jsonb_column_scans.ndjson")) do |file|
          output[:bad_queries].each do |query|
            file.puts(JSON.generate(query))
          end
        end
      end

      private

      def has_operator_in_where?(query)
        return false unless query.match?(JSONB_MATCH_OPERATOR_EXPRESSION)

        clauses = query.split(/\sWHERE\s|\sJOIN\s/)
        return false if clauses.length < 2

        clauses[1..].each do |c|
          return true if c.include?('::jsonb')
        end
      end
    end
  end
end

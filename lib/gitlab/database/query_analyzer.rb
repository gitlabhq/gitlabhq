# frozen_string_literal: true

module Gitlab
  module Database
    # The purpose of this class is to implement a various query analyzers based on `pg_query`
    # And process them all via `Gitlab::Database::QueryAnalyzers::*`
    class QueryAnalyzer
      ANALYZERS = [].freeze

      Parsed = Struct.new(
        :sql, :connection, :pg
      )

      def hook!
        @subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          process_sql(event.payload[:sql], event.payload[:connection])
        end
      end

      private

      def process_sql(sql, connection)
        analyzers = enabled_analyzers(connection)
        return unless analyzers.any?

        parsed = parse(sql, connection)
        return unless parsed

        analyzers.each do |analyzer|
          analyzer.analyze(parsed)
        rescue => e # rubocop:disable Style/RescueStandardError
          # We catch all standard errors to prevent validation errors to introduce fatal errors in production
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end
      end

      def enabled_analyzers(connection)
        ANALYZERS.select do |analyzer|
          analyzer.enabled?(connection)
        rescue StandardError => e # rubocop:disable Style/RescueStandardError
          # We catch all standard errors to prevent validation errors to introduce fatal errors in production
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end
      end

      def parse(sql, connection)
        parsed = PgQuery.parse(sql)
        return unless parsed

        normalized = PgQuery.normalize(sql)
        Parsed.new(normalized, connection, parsed)
      rescue PgQuery::ParseError => e
        # Ignore PgQuery parse errors (due to depth limit or other reasons)
        Gitlab::ErrorTracking.track_exception(e)

        nil
      end
    end
  end
end

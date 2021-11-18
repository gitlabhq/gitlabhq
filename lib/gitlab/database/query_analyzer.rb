# frozen_string_literal: true

module Gitlab
  module Database
    # The purpose of this class is to implement a various query analyzers based on `pg_query`
    # And process them all via `Gitlab::Database::QueryAnalyzers::*`
    #
    # Sometimes this might cause errors in specs.
    # This is best to be disable with `describe '...', query_analyzers: false do`
    class QueryAnalyzer
      include ::Singleton

      Parsed = Struct.new(
        :sql, :connection, :pg
      )

      attr_reader :all_analyzers

      def initialize
        @all_analyzers = []
      end

      def hook!
        @subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          # In some cases analyzer code might trigger another SQL call
          # to avoid stack too deep this detects recursive call of subscriber
          with_ignored_recursive_calls do
            process_sql(event.payload[:sql], event.payload[:connection])
          end
        end
      end

      def within
        # Due to singleton nature of analyzers
        # only an outer invocation of the `.within`
        # is allowed to initialize them
        return yield if already_within?

        begin!

        begin
          yield
        ensure
          end!
        end
      end

      def already_within?
        # If analyzers are set they are already configured
        !enabled_analyzers.nil?
      end

      def process_sql(sql, connection)
        analyzers = enabled_analyzers
        return unless analyzers&.any?

        parsed = parse(sql, connection)
        return unless parsed

        analyzers.each do |analyzer|
          next if analyzer.suppressed?

          analyzer.analyze(parsed)
        rescue StandardError => e
          # We catch all standard errors to prevent validation errors to introduce fatal errors in production
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end
      end

      private

      # Enable query analyzers
      def begin!
        analyzers = all_analyzers.select do |analyzer|
          if analyzer.enabled?
            analyzer.begin!

            true
          end
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)

          false
        end

        Thread.current[:query_analyzer_enabled_analyzers] = analyzers
      end

      # Disable enabled query analyzers
      def end!
        enabled_analyzers.select do |analyzer|
          analyzer.end!
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end

        Thread.current[:query_analyzer_enabled_analyzers] = nil
      end

      def enabled_analyzers
        Thread.current[:query_analyzer_enabled_analyzers]
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

      def with_ignored_recursive_calls
        return if Thread.current[:query_analyzer_recursive]

        begin
          Thread.current[:query_analyzer_recursive] = true
          yield
        ensure
          Thread.current[:query_analyzer_recursive] = nil
        end
      end
    end
  end
end

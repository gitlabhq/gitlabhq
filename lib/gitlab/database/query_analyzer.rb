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

      class Parsed
        include Gitlab::Utils::StrongMemoize

        attr_reader :raw, :connection, :event_name, :error

        def initialize(raw, connection, event_name)
          @raw = raw
          @connection = connection
          @event_name = normalize_event_name(event_name)
          @error = nil
        end

        def sql
          try_parse do
            PgQuery.normalize(raw)
          end
        end
        strong_memoize_attr :sql

        def pg
          try_parse do
            PgQuery.parse(raw)
          end
        end
        strong_memoize_attr :pg

        private

        def try_parse
          return if error

          yield
        rescue PgQuery::ParseError => e
          # Ignore PgQuery parse errors (due to depth limit or other reasons)
          Gitlab::ErrorTracking.track_exception(e)
          @error = e

          nil
        end

        def normalize_event_name(event_name)
          split_event_name = event_name.to_s.downcase.split(' ')

          split_event_name.size > 1 ? split_event_name.from(1).join('_') : split_event_name.join('_')
        end
      end

      attr_reader :all_analyzers

      def initialize
        @all_analyzers = []
      end

      # @info most common event names are:
      #       Model Load, Model Create, Model Update, Model Pluck, Model Destroy, Model Insert, Model Delete All
      #       Model Exists?, nil, TRANSACTION, SCHEMA
      def hook!
        @subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          # In some cases analyzer code might trigger another SQL call
          # to avoid stack too deep this detects recursive call of subscriber
          with_ignored_recursive_calls do
            process_sql(event.payload[:sql], event.payload[:connection], event.payload[:name].to_s)
          end
        end
      end

      def within(analyzers = all_analyzers)
        newly_enabled_analyzers = begin!(analyzers)

        begin
          yield
        ensure
          end!(newly_enabled_analyzers)
        end
      end

      # Enable query analyzers (only the ones that were not yet enabled)
      # Returns a list of newly enabled analyzers
      def begin!(analyzers)
        analyzers.select do |analyzer|
          next if enabled_analyzers.include?(analyzer)

          if analyzer.enabled?
            analyzer.begin!
            enabled_analyzers.append(analyzer)

            true
          end
        rescue StandardError, ::Gitlab::Database::QueryAnalyzers::Base::QueryAnalyzerError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)

          false
        end
      end

      # Disable enabled query analyzers (only the ones that were enabled previously)
      def end!(analyzers)
        analyzers.each do |analyzer|
          next unless enabled_analyzers.delete(analyzer)

          analyzer.end!
        rescue StandardError, ::Gitlab::Database::QueryAnalyzers::Base::QueryAnalyzerError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end
      end

      private

      def enabled_analyzers
        Thread.current[:query_analyzer_enabled_analyzers] ||= []
      end

      def process_sql(sql, connection, event_name)
        analyzers = enabled_analyzers
        return unless analyzers&.any?

        parsed = Parsed.new(sql, connection, event_name)

        analyzers.each do |analyzer|
          next if analyzer.suppressed? && !analyzer.requires_tracking?(parsed)

          analyzer.analyze(parsed)
        rescue StandardError, ::Gitlab::Database::QueryAnalyzers::Base::QueryAnalyzerError => e
          # We catch all standard errors to prevent validation errors to introduce fatal errors in production
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end
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

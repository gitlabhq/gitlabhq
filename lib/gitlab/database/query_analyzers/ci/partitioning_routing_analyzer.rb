# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      module Ci
        # The purpose of this analyzer is to detect queries not going through a partitioning routing table
        class PartitioningRoutingAnalyzer < Database::QueryAnalyzers::Base
          RoutingTableNotUsedError = Class.new(QueryAnalyzerError)

          ENABLED_TABLES = %w[
            ci_builds
            ci_builds_metadata
            ci_job_artifacts
            ci_pipeline_variables
            ci_pipelines
            ci_stages
          ].freeze

          class << self
            def enabled?
              ::Feature::FlipperFeature.table_exists? &&
                ::Feature.enabled?(:ci_partitioning_analyze_queries, type: :ops)
            end

            def analyze(parsed)
              # This analyzer requires the PgQuery parsed query to be present
              return unless parsed.pg

              analyze_legacy_tables_usage(parsed)
            end

            private

            def analyze_legacy_tables_usage(parsed)
              detected = ENABLED_TABLES & (parsed.pg.dml_tables + parsed.pg.select_tables)

              return if detected.none?

              ::Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
                RoutingTableNotUsedError.new("Detected non-partitioned table use #{detected.inspect}: #{parsed.sql}")
              )
            end
          end
        end
      end
    end
  end
end

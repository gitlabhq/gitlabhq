# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      # The purpose of this analyzer is to observe via prometheus metrics
      # all unique schemas observed on a given connection
      #
      # This effectively allows to do sample 1% or 0.01% of queries hitting
      # system and observe if on a given connection we observe queries that
      # are misaligned (`ci_replica` sees queries doing accessing only `gitlab_main`)
      #
      class GitlabSchemasMetrics < Base
        class << self
          def enabled?
            ::Feature::FlipperFeature.table_exists? &&
              Feature.enabled?(:query_analyzer_gitlab_schema_metrics, type: :ops)
          end

          def analyze(parsed)
            # This analyzer requires the PgQuery parsed query to be present
            return unless parsed.pg

            db_config_name = ::Gitlab::Database.db_config_name(parsed.connection)
            return unless db_config_name

            gitlab_schemas = ::Gitlab::Database::GitlabSchema.table_schemas!(parsed.pg.tables)
            return if gitlab_schemas.empty?

            # to reduce amount of labels sort schemas used
            gitlab_schemas = gitlab_schemas.to_a.sort.join(",")

            schemas_metrics.increment({
              gitlab_schemas: gitlab_schemas,
              db_config_name: db_config_name
            })
          end

          def schemas_metrics
            @schemas_metrics ||= ::Gitlab::Metrics.counter(
              :gitlab_database_decomposition_gitlab_schemas_used,
              'The number of observed schemas dependent on connection'
            )
          end
        end
      end
    end
  end
end

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
              Feature.enabled?(:query_analyzer_gitlab_schema_metrics)
          end

          def analyze(parsed)
            db_config_name = ::Gitlab::Database.db_config_name(parsed.connection)
            return unless db_config_name

            gitlab_schemas = ::Gitlab::Database::GitlabSchema.table_schemas(parsed.pg.tables)
            return if gitlab_schemas.empty?

            # to reduce amount of labels sort schemas used
            gitlab_schemas = gitlab_schemas.to_a.sort.join(",")

            # Temporary feature to observe relation of `gitlab_schemas` to `db_config_name`
            # depending on primary model
            ci_dedicated_primary_connection = ::Ci::ApplicationRecord.connection_class? &&
              ::Ci::ApplicationRecord.load_balancer.configuration.use_dedicated_connection?

            schemas_metrics.increment({
              gitlab_schemas: gitlab_schemas,
              db_config_name: db_config_name,
              ci_dedicated_primary_connection: ci_dedicated_primary_connection
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

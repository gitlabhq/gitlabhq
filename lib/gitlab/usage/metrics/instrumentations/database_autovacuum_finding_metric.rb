# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class DatabaseAutovacuumFindingMetric < GenericMetric
          # Finding codes emitted by Database::Diagnostics::Checks::AutovacuumSettings.
          # These name the problem, not the setting it was found on. A spec asserts the
          # check still emits each one, so a rename there cannot silently turn a metric
          # into a permanent false.
          FINDING_CODES = %w[
            autovacuum_disabled
            autovacuum_throttling_disabled
            autovacuum_max_workers_low
            autovacuum_cost_limit_low
            autovacuum_work_mem_inherited
          ].freeze

          def initialize(metric_definition)
            super

            return if FINDING_CODES.include?(options[:finding_code])

            raise ArgumentError, "option 'finding_code' must be one of: #{FINDING_CODES.join(', ')}"
          end

          value do
            findings.any? { |finding| finding[:code] == options[:finding_code] }
          end

          private

          # Read on the primary, since a replica can carry different GUC values than
          # the server autovacuum actually runs on.
          def findings
            connection = ::Gitlab::Database.database_base_models[::Gitlab::Database::MAIN_DATABASE_NAME].connection

            ::Gitlab::Database::LoadBalancing::SessionMap
              .current(connection.load_balancer)
              .use_primary do
                ::Gitlab::Database::Diagnostics::Checks::AutovacuumSettings.new(connection).execute[:findings]
              end
          end
        end
      end
    end
  end
end

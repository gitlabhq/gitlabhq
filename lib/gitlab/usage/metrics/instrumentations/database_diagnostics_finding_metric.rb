# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Reports whether the Database::Diagnostics check named by the `check` option
        # emits the finding code given in the `finding_code` option, read from the
        # main database primary.
        #
        # Usage example
        #
        # instrumentation_class: DatabaseDiagnosticsFindingMetric
        # options:
        #   check: autovacuum_settings
        #   finding_code: autovacuum_disabled
        class DatabaseDiagnosticsFindingMetric < GenericMetric
          CHECKS = {
            'autovacuum_settings' => ::Gitlab::Database::Diagnostics::Checks::AutovacuumSettings,
            'search_path' => ::Gitlab::Database::Diagnostics::Checks::SchemaResolution
          }.freeze

          value do
            findings.any? { |finding| finding[:code] == options[:finding_code] }
          end

          def initialize(metric_definition)
            super

            return if CHECKS.key?(options[:check])

            raise ArgumentError, "option 'check' must be one of: #{CHECKS.keys.join(', ')}"
          end

          private

          # Read on the primary, since a replica can carry different server settings
          # and a different schema layout than the server GitLab writes to.
          def findings
            connection = ::Gitlab::Database.database_base_models[::Gitlab::Database::MAIN_DATABASE_NAME].connection

            ::Gitlab::Database::LoadBalancing::SessionMap
              .current(connection.load_balancer)
              .use_primary do
                CHECKS.fetch(options[:check]).new(connection).execute[:findings]
              end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      module HealthStatus
        module Indicators
          class AutovacuumActiveOnTable
            def initialize(context)
              @context = context
            end

            def evaluate
              return Signals::NotAvailable.new(self.class, reason: 'indicator disabled') unless enabled?

              autovacuum_active_on = active_autovacuums_for(context.tables)

              if autovacuum_active_on.empty?
                Signals::Normal.new(self.class, reason: 'no autovacuum running on any relevant tables')
              else
                Signals::Stop.new(self.class, reason: "autovacuum running on: #{autovacuum_active_on.join(', ')}")
              end
            end

            private

            attr_reader :context

            def enabled?
              Feature.enabled?(:batched_migrations_health_status_autovacuum, type: :ops)
            end

            def active_autovacuums_for(tables)
              Gitlab::Database::PostgresAutovacuumActivity.for_tables(tables)
            end
          end
        end
      end
    end
  end
end

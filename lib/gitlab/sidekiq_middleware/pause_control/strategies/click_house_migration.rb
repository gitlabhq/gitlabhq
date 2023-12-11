# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        class ClickHouseMigration < Base
          override :should_pause?
          def should_pause?
            return false unless Feature.enabled?(:pause_clickhouse_workers_during_migration)

            ClickHouse::MigrationSupport::ExclusiveLock.pause_workers?
          end
        end
      end
    end
  end
end

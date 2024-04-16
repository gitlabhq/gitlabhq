# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        class ClickHouseMigration < Base
          override :should_pause?
          def should_pause?
            ::ClickHouse::MigrationSupport::ExclusiveLock.pause_workers?
          end
        end
      end
    end
  end
end

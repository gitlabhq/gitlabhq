# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        class ClickHouseMigration < Base
          override :should_pause?
          def should_pause?
            Feature.enabled?(:suspend_click_house_data_ingestion, type: :worker) ||
              ::ClickHouse::MigrationSupport::ExclusiveLock.pause_workers?
          end
        end
      end
    end
  end
end

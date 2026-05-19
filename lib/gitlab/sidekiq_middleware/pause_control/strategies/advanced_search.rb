# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        class AdvancedSearch < Base
          override :should_pause?
          def should_pause?
            Gitlab::CurrentSettings.advanced_search_indexing_paused?
          end
        end
      end
    end
  end
end

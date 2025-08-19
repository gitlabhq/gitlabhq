# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        class ActiveContext < Base
          override :should_pause?
          def should_pause?
            ::Ai::ActiveContext.paused?
          end
        end
      end
    end
  end
end

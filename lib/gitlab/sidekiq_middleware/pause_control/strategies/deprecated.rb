# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        # This strategy will never pause a job. It used to indicate that a job is no longer paused
        class Deprecated < Base
          override :should_pause?
          def should_pause?
            false
          end
        end
      end
    end
  end
end

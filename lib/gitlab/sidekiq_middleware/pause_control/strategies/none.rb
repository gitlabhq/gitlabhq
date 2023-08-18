# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        # This strategy will never pause a job
        class None < Base
          override :should_pause?
          def should_pause?
            false
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        class Zoekt < Base
          override :should_pause?
          def should_pause?
            ::Feature.enabled?(:zoekt_pause_indexing, type: :ops)
          end
        end
      end
    end
  end
end

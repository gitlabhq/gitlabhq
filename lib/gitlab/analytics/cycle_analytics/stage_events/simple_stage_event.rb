# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        # Represents a simple event that usually refers to one database column and does not require additional user input
        class SimpleStageEvent < StageEvent
        end
      end
    end
  end
end

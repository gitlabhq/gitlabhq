# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        # Base class for expressing an event that can be used for a stage.
        class StageEvent
          def initialize(params)
            @params = params
          end

          def self.name
            raise NotImplementedError
          end

          def self.identifier
            raise NotImplementedError
          end

          def object_type
            raise NotImplementedError
          end
        end
      end
    end
  end
end

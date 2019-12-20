# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        # Base class for expressing an event that can be used for a stage.
        class StageEvent
          include Gitlab::CycleAnalytics::MetricsTables

          delegate :label_based?, to: :class

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

          # Each StageEvent must expose a timestamp or a timestamp like expression in order to build a range query.
          # Example: get me all the Issue records between start event end end event
          def timestamp_projection
            raise NotImplementedError
          end

          # Optionally a StageEvent may apply additional filtering or join other tables on the base query.
          def apply_query_customization(query)
            query
          end

          def self.label_based?
            false
          end

          private

          attr_reader :params
        end
      end
    end
  end
end

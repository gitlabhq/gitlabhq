# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module Observability
        class EventLogger
          EVENTS = {
            'worker_transition' => Events::WorkerTransitionEvent,
            'worker_optimization' => Events::WorkerOptimizationEvent,
            'job_transition' => Events::JobTransitionEvent
          }.freeze

          class << self
            def log(event:, record:, **attributes)
              EVENTS.fetch(event.to_s) { |key| raise KeyError, "#{key} is not a valid event" }.new(
                record, **attributes
              ).log
            end
          end
        end
      end
    end
  end
end

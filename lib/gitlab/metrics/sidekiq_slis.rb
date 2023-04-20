# frozen_string_literal: true

module Gitlab
  module Metrics
    module SidekiqSlis
      EXECUTION_URGENCY_DURATIONS = {
        "high" => 10,
        "low" => 300,
        "throttled" => 300
      }.freeze
      # workers without urgency attribute have "low" urgency by default in
      # WorkerAttributes.get_urgency, just mirroring it here
      DEFAULT_EXECUTION_URGENCY_DURATION = EXECUTION_URGENCY_DURATIONS["low"]

      class << self
        def initialize_slis!(possible_labels)
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:sidekiq_execution, possible_labels)
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:sidekiq_execution, possible_labels)
        end

        def record_execution_apdex(labels, job_completion_duration)
          urgency_requirement = execution_duration_for_urgency(labels[:urgency])
          Gitlab::Metrics::Sli::Apdex[:sidekiq_execution].increment(
            labels: labels,
            success: job_completion_duration < urgency_requirement
          )
        end

        def record_execution_error(labels, error)
          Gitlab::Metrics::Sli::ErrorRate[:sidekiq_execution].increment(labels: labels, error: error)
        end

        def execution_duration_for_urgency(urgency)
          EXECUTION_URGENCY_DURATIONS.fetch(urgency, DEFAULT_EXECUTION_URGENCY_DURATION)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Adapters
      # Default recording backend before a persistent one is wired in. It keeps
      # the facade functional and lets the recorder contract be exercised without
      # a database. It cannot verify that referenced records exist. Not for
      # production data: per-process, non-durable, and not thread-safe.
      class InMemoryEvaluationRecorder < Ports::EvaluationRecorder
        def initialize
          @evaluations = {}
          @sequence = 0
        end

        def record(attributes)
          normalized = recordable_attributes(attributes)

          violations = (normalized[:violations] || []).map do |entry|
            @sequence += 1
            PolicyStore::Violation.new(id: @sequence, details: deep_copy(entry['details']))
          end

          @sequence += 1
          evaluation = build_evaluation(@sequence, normalized, violations)
          @evaluations[evaluation.id] = evaluation

          evaluation
        end

        private

        def build_evaluation(id, attributes, violations)
          attributes = deep_copy(attributes)

          PolicyStore::Evaluation.new(
            id: id,
            organization_id: attributes[:organization_id],
            policy_id: attributes[:policy_id],
            policy_version: attributes[:policy_version],
            trigger_type: attributes[:trigger_type],
            mode: attributes[:mode],
            verdict: attributes[:verdict],
            evaluated_at: attributes[:evaluated_at],
            project_id: attributes[:project_id],
            environment_id: attributes[:environment_id],
            user_id: attributes[:user_id],
            violations: violations
          )
        end

        def deep_copy(value)
          case value
          when Hash then value.transform_values { |nested| deep_copy(nested) }
          when Array then value.map { |item| deep_copy(item) }
          when String then value.dup
          else value
          end
        end
      end
    end
  end
end

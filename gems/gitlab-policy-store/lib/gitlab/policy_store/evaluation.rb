# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class Evaluation
      attr_reader :id, :organization_id, :policy_id, :policy_version, :trigger_type,
        :mode, :verdict, :evaluated_at, :project_id, :environment_id, :user_id,
        :violations

      # rubocop:disable Metrics/ParameterLists -- value object; one keyword per field
      def initialize(
        id:, organization_id:, policy_id:, policy_version:, trigger_type:, mode:,
        verdict:, evaluated_at:, project_id: nil, environment_id: nil, user_id: nil,
        violations: [])
        # rubocop:enable Metrics/ParameterLists
        @id = id
        @organization_id = organization_id
        @policy_id = policy_id
        @policy_version = policy_version
        @trigger_type = trigger_type
        @mode = mode
        @verdict = verdict
        @evaluated_at = evaluated_at
        @project_id = project_id
        @environment_id = environment_id
        @user_id = user_id
        # Entries are already-frozen Violation value objects; freezing the
        # array closes the remaining mutation path (push/clear).
        @violations = violations.freeze

        freeze
      end

      def to_h
        {
          id: id,
          organization_id: organization_id,
          policy_id: policy_id,
          policy_version: policy_version,
          trigger_type: trigger_type,
          mode: mode,
          verdict: verdict,
          evaluated_at: evaluated_at,
          project_id: project_id,
          environment_id: environment_id,
          user_id: user_id,
          violations: violations.map(&:to_h)
        }
      end

      def ==(other)
        other.is_a?(self.class) && other.to_h == to_h
      end
      alias_method :eql?, :==

      def hash
        to_h.hash
      end
    end
  end
end

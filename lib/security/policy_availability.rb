# frozen_string_literal: true

module Security
  class PolicyAvailability
    class Licensed
      def initialize(feature)
        @feature = feature
      end

      def enabled_for?(subject)
        subject.licensed_feature_available?(@feature)
      end
    end

    class DependencyFirewall
      def enabled_for?(subject)
        Gitlab.ee? && ::Security::DependencyFirewall::Availability.enforced_for?(subject)
      end
    end

    REGISTRY = {
      security_orchestration_policies: PolicyAvailability::Licensed.new(:security_orchestration_policies),
      dependency_firewall: PolicyAvailability::DependencyFirewall.new
    }.freeze

    def self.any_available?(subject)
      return false unless subject

      REGISTRY.values.any? { |evaluator| evaluator.enabled_for?(subject) }
    end

    def self.available?(subject, policy_type)
      evaluator = REGISTRY[policy_type]

      return false unless evaluator
      return false unless subject

      evaluator.enabled_for?(subject)
    end
  end
end

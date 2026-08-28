# frozen_string_literal: true

require_relative "policy_store/version"
require_relative "policy_store/triggers"
require_relative "policy_store/actions"
require_relative "policy_store/rules"
require_relative "policy_store/policy"
require_relative "policy_store/json_value"
require_relative "policy_store/scope_transpiler"
require_relative "policy_store/rego_package"
require_relative "policy_store/rule_transpiler"
require_relative "policy_store/rule_program_merger"
require_relative "policy_store/violation"
require_relative "policy_store/evaluation"
require_relative "policy_store/enumerated_attribute_validation"
require_relative "policy_store/ports/policy_repository"
require_relative "policy_store/ports/evaluation_recorder"
require_relative "policy_store/adapters/in_memory_policy_repository"
require_relative "policy_store/adapters/in_memory_evaluation_recorder"
require_relative "policy_store/configuration"

module Gitlab
  # Public facade for the Policy Store component.
  #
  # This is the ONLY entry point callers should use. Everything behind it is
  # internal. All persistence goes through injectable ports (a
  # Gitlab::PolicyStore::Ports::PolicyRepository for policies, a
  # Gitlab::PolicyStore::Ports::EvaluationRecorder for evaluation results), so
  # the in-monolith backends used today can be swapped for a remote service
  # later without changing any caller.
  module PolicyStore
    # Domain errors are defined here so callers never need to rescue persistence-
    # or transport-specific exceptions across the component boundary.
    Error = Class.new(StandardError)
    NotFound = Class.new(Error)
    ValidationError = Class.new(Error)

    class << self
      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Configuration.new(
          Adapters::InMemoryPolicyRepository.new,
          Adapters::InMemoryEvaluationRecorder.new
        )
      end

      # Discards the configured repository, and with it any state the in-memory
      # adapter accumulated. Intended for specs and console sessions; callers
      # that configured a repository must configure it again afterwards.
      def reset_configuration!
        @configuration = nil
      end

      def create(attributes)
        configuration.repository.create(attributes)
      end

      def update(id, attributes)
        configuration.repository.update(id, attributes)
      end

      def find(id)
        configuration.repository.find(id)
      end

      def delete(id)
        configuration.repository.delete(id)
      end

      def list(organization_id:, trigger_type: nil)
        configuration.repository.list(organization_id: organization_id, trigger_type: trigger_type)
      end

      def record_evaluation(attributes)
        configuration.evaluation_recorder.record(attributes)
      end
    end
  end
end

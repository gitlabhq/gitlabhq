# frozen_string_literal: true

require_relative "policy_store/version"
require_relative "policy_store/policy"
require_relative "policy_store/scope_transpiler"
require_relative "policy_store/ports/policy_repository"
require_relative "policy_store/adapters/in_memory_policy_repository"
require_relative "policy_store/configuration"

module Gitlab
  # Public facade for the Policy Store component.
  #
  # This is the ONLY entry point callers should use. Everything behind it is
  # internal. All persistence goes through an injectable repository (a
  # Gitlab::PolicyStore::Ports::PolicyRepository), so the in-monolith
  # backend used today can be swapped for a remote service later without
  # changing any caller.
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
        @configuration ||= Configuration.new(Adapters::InMemoryPolicyRepository.new)
      end

      def create(attributes)
        configuration.repository.create(attributes)
      end

      def find(id)
        configuration.repository.find(id)
      end

      def delete(id)
        configuration.repository.delete(id)
      end

      def list(organization_id:)
        configuration.repository.list(organization_id: organization_id)
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Adapters
      # Default storage backend for the component before a persistent one is
      # wired in. It keeps the facade functional and lets the repository contract
      # be exercised without a database. Not for production data (per-process,
      # non-durable).
      class InMemoryPolicyRepository < Ports::PolicyRepository
        def initialize
          @policies = {}
          @sequence = 0
        end

        def create(attributes)
          normalized = normalize_attributes(attributes)
          validate_required_attributes!(normalized)
          normalized = with_compiled_scope(normalized)

          @sequence += 1
          @policies[@sequence] = build_policy(@sequence, normalized)
        end

        def find(id)
          @policies.fetch(id) { raise PolicyStore::NotFound, "Policy with id #{id} was not found" }
        end

        def delete(id)
          @policies.delete(id) { raise PolicyStore::NotFound, "Policy with id #{id} was not found" }

          nil
        end

        def list(organization_id:)
          @policies.values.select { |policy| policy.organization_id == organization_id }
        end

        private

        def build_policy(id, attributes)
          PolicyStore::Policy.new(
            id: id,
            organization_id: attributes[:organization_id],
            name: attributes[:name],
            version: attributes.fetch(:version, 1),
            trigger_id: attributes[:trigger_id],
            rules: attributes.fetch(:rules, {}),
            actions: attributes.fetch(:actions, []),
            policy_scope: attributes[:policy_scope],
            scope_rego: attributes[:scope_rego],
            mode: attributes.fetch(:mode, 'enforce'),
            lifecycle_state: attributes.fetch(:lifecycle_state, 'active')
          )
        end
      end
    end
  end
end

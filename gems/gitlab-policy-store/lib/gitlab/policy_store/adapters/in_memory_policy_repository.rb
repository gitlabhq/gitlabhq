# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Adapters
      # Default storage backend for the component before a persistent one is
      # wired in. It keeps the facade functional and lets the repository contract
      # be exercised without a database. Not for production data: per-process,
      # non-durable, and not thread-safe.
      class InMemoryPolicyRepository < Ports::PolicyRepository
        def initialize
          @policies = {}
          @sequence = 0
        end

        def create(attributes)
          normalized = creatable_attributes(attributes)
          validate_required_attributes!(normalized)
          validate_authored_text_limits!(normalized)
          validate_enumerated_attributes!(normalized, ENUMERATED_ATTRIBUTES)
          validate_entry_limits!(normalized)
          validate_action_shapes!(normalized)
          validate_name_available!(normalized)
          normalized = with_compiled_scope(normalized)
          normalized = with_compiled_rules(normalized)
          validate_compiled_text_limits!(normalized)

          @sequence += 1
          @policies[@sequence] = build_policy(@sequence, normalized)

          find(@sequence)
        end

        def update(id, attributes)
          existing = find(id)
          changes = changes_excluding_restated(existing.to_h, updatable_changes(attributes, existing.to_h))
          authored = existing.to_h.merge(changes)
          validate_required_attributes!(authored)
          validate_authored_text_limits!(authored)
          validate_enumerated_attributes!(authored, ENUMERATED_ATTRIBUTES)
          validate_entry_limits!(changes)
          validate_action_shapes!(changes)
          validate_name_available!(authored, excluding_id: id)

          scoped = with_updated_scope(existing.to_h, changes)
          merged = with_updated_rules(scoped, changes)

          return existing if merged == existing.to_h

          validate_compiled_text_limits!(merged)

          @policies[id] = build_policy(id, merged.merge(version: existing.version + 1))

          find(id)
        end

        def find(id)
          copy_of(@policies.fetch(id) { raise PolicyStore::NotFound, "Policy with id #{id} was not found" })
        end

        def delete(id)
          @policies.delete(id) { raise PolicyStore::NotFound, "Policy with id #{id} was not found" }

          nil
        end

        def list(organization_id:, trigger_type: nil, ids: nil, offset: 0, per_page: DEFAULT_PER_PAGE)
          validate_ids_size!(ids) if ids

          matching = @policies.values.select do |policy|
            policy.organization_id == organization_id &&
              (trigger_type.nil? || policy.trigger_type == trigger_type) &&
              (ids.nil? || ids.include?(policy.id))
          end

          return paginated_result(matching, per_page: matching.size) { |policy| copy_of(policy) } if ids

          offset, per_page = clamped_pagination(offset: offset, per_page: per_page)
          fetched = matching[offset, per_page + 1].to_a

          paginated_result(fetched, per_page: per_page) { |policy| copy_of(policy) }
        end

        private

        def validate_name_available!(attributes, excluding_id: nil)
          taken = @policies.any? do |id, policy|
            id != excluding_id &&
              policy.organization_id == attributes[:organization_id] &&
              policy.name == attributes[:name]
          end

          raise PolicyStore::ValidationError, 'Name has already been taken' if taken
        end

        def build_policy(id, attributes)
          attributes = deep_copy(attributes)

          PolicyStore::Policy.new(
            id: id,
            organization_id: attributes[:organization_id],
            namespace_id: attributes[:namespace_id],
            name: attributes[:name],
            description: attributes[:description],
            version: attributes.fetch(:version, 1),
            trigger_type: attributes[:trigger_type],
            rules: attributes.fetch(:rules, []),
            actions: attributes.fetch(:actions, []),
            policy_scope: attributes[:policy_scope],
            scope_rego: attributes[:scope_rego],
            scope_dimensions: attributes[:scope_dimensions],
            mode: attributes.fetch(:mode, DEFAULT_MODE),
            lifecycle_state: attributes.fetch(:lifecycle_state, DEFAULT_LIFECYCLE_STATE),
            created_at: attributes[:created_at],
            updated_at: attributes[:updated_at]
          )
        end

        def copy_of(policy)
          build_policy(policy.id, policy.to_h)
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

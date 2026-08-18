# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Ports
      # Contract every storage backend must satisfy. The in-memory adapter
      # implements it today; a future remote (e.g. gRPC) adapter would implement
      # the same interface, keeping the facade and callers unchanged.
      class PolicyRepository
        REQUIRED_ATTRIBUTES = [:organization_id, :name, :trigger_type].freeze

        # Text length limits matching database constraints
        TEXT_LIMITS = {
          name: 255,
          description: 4096,
          scope_rego: 4096
        }.freeze

        COMPILED_TEXT_ATTRIBUTES = [:scope_rego].freeze
        private_constant :COMPILED_TEXT_ATTRIBUTES

        UPDATABLE_ATTRIBUTES = %i[
          name description trigger_type rules actions policy_scope scope_rego mode lifecycle_state
        ].freeze

        # Accepted by `create` and `update` and dropped, so a caller may hand a whole
        # policy back without stripping it first.
        IMMUTABLE_ATTRIBUTES = %i[id version organization_id namespace_id created_at updated_at].freeze

        # The subset of IMMUTABLE_ATTRIBUTES `update` will not silently ignore, because
        # a differing value there reads as a request to re-home the policy rather than
        # as a resend. `version` and the timestamps stay tolerated: comparing them would
        # be optimistic locking by accident, reported as a validation error.
        IDENTITY_ATTRIBUTES = %i[id organization_id namespace_id].freeze

        CREATABLE_ATTRIBUTES = (UPDATABLE_ATTRIBUTES + %i[organization_id namespace_id]).freeze

        SCOPE_FORM_TYPES = { policy_scope: Hash, scope_rego: String }.freeze

        NON_NULLABLE_ATTRIBUTES = %i[rules actions mode lifecycle_state].freeze

        MODES = %w[audit warn enforce].freeze
        LIFECYCLE_STATES = %w[active disabled].freeze

        DEFAULT_MODE = 'enforce'
        DEFAULT_LIFECYCLE_STATE = 'active'

        # @param _attributes [Hash] the policy attributes, limited to CREATABLE_ATTRIBUTES;
        #   IMMUTABLE_ATTRIBUTES are accepted and dropped, so every policy starts at version 1
        # @return [Gitlab::PolicyStore::Policy] the created policy
        # @raise [Gitlab::PolicyStore::ValidationError] if the policy is invalid, its name is
        #   taken, an attribute is outside CREATABLE_ATTRIBUTES and IMMUTABLE_ATTRIBUTES, or
        #   one of NON_NULLABLE_ATTRIBUTES is explicitly nil
        def create(_attributes)
          raise NotImplementedError
        end

        # @param _id [Integer] the policy ID
        # @param _attributes [Hash] the changes, limited to UPDATABLE_ATTRIBUTES;
        #   IMMUTABLE_ATTRIBUTES are accepted and dropped, except that an IDENTITY_ATTRIBUTES
        #   value must match what is stored
        # @return [Gitlab::PolicyStore::Policy] the updated policy, with `version` bumped by one,
        #   or the stored policy untouched when no supplied value differs from it
        # @raise [Gitlab::PolicyStore::NotFound] if the policy does not exist
        # @raise [Gitlab::PolicyStore::ValidationError] if the result is invalid, its name is
        #   taken, an attribute is outside UPDATABLE_ATTRIBUTES and IMMUTABLE_ATTRIBUTES, one of
        #   IDENTITY_ATTRIBUTES differs from the stored policy, or one of
        #   NON_NULLABLE_ATTRIBUTES is explicitly nil
        def update(_id, _attributes)
          raise NotImplementedError
        end

        # @param _id [Integer] the policy ID
        # @return [Gitlab::PolicyStore::Policy] the found policy
        # @raise [Gitlab::PolicyStore::NotFound] if the policy does not exist
        def find(_id)
          raise NotImplementedError
        end

        # @param _id [Integer] the policy ID
        # @return [nil]
        # @raise [Gitlab::PolicyStore::NotFound] if the policy does not exist
        def delete(_id)
          raise NotImplementedError
        end

        # @param organization_id [Integer] the organization ID
        # @param trigger_type [String, nil] returns every trigger when nil
        # @return [Array<Gitlab::PolicyStore::Policy>] the policies
        def list(organization_id:, trigger_type: nil)
          raise NotImplementedError
        end

        private

        def normalize_attributes(attributes)
          attributes.to_h.transform_keys(&:to_sym).transform_values { |value| JsonValue.deep_stringify(value) }
        end

        def creatable_attributes(attributes)
          normalized = normalize_attributes(attributes)

          reject_unknown_attributes!(normalized, CREATABLE_ATTRIBUTES)
          reject_null_attributes!(normalized)
          reject_malformed_scope!(normalized)

          normalized.slice(*CREATABLE_ATTRIBUTES)
        end

        def updatable_changes(attributes, stored)
          normalized = normalize_attributes(attributes)

          reject_unknown_attributes!(normalized, UPDATABLE_ATTRIBUTES)
          reject_identity_changes!(normalized, stored)
          reject_null_attributes!(normalized)
          reject_malformed_scope!(normalized)

          normalized.slice(*UPDATABLE_ATTRIBUTES)
        end

        def reject_unknown_attributes!(attributes, permitted)
          unknown = attributes.keys - permitted - IMMUTABLE_ATTRIBUTES
          return if unknown.empty?

          raise PolicyStore::ValidationError, "Unknown attributes: #{unknown.join(', ')}"
        end

        def reject_identity_changes!(attributes, stored)
          conflicting = IDENTITY_ATTRIBUTES.select do |attribute|
            attributes.key?(attribute) && attributes[attribute] != stored[attribute]
          end
          return if conflicting.empty?

          raise PolicyStore::ValidationError, "Attributes cannot be changed: #{conflicting.join(', ')}"
        end

        def reject_malformed_scope!(attributes)
          malformed = SCOPE_FORM_TYPES.reject do |attribute, type|
            !attributes.key?(attribute) || attributes[attribute].nil? || attributes[attribute].is_a?(type)
          end
          return if malformed.empty?

          raise PolicyStore::ValidationError,
            malformed.map { |attribute, type| "#{attribute} must be a #{type.name.downcase}" }.join(', ')
        end

        def reject_null_attributes!(attributes)
          nulled = NON_NULLABLE_ATTRIBUTES.select do |attribute|
            attributes.key?(attribute) && attributes[attribute].nil?
          end
          return if nulled.empty?

          raise PolicyStore::ValidationError, "Attributes cannot be null: #{nulled.join(', ')}"
        end

        def validate_required_attributes!(attributes)
          missing = REQUIRED_ATTRIBUTES.select { |attr| blank?(attributes[attr]) }
          return if missing.empty?

          raise PolicyStore::ValidationError,
            "Missing required attributes: #{missing.join(', ')}"
        end

        def validate_authored_text_limits!(attributes)
          validate_text_limits!(attributes, TEXT_LIMITS.except(*COMPILED_TEXT_ATTRIBUTES))
        end

        def validate_compiled_text_limits!(attributes)
          validate_text_limits!(attributes, TEXT_LIMITS.slice(*COMPILED_TEXT_ATTRIBUTES))
        end

        def validate_text_limits!(attributes, limits = TEXT_LIMITS)
          limits.each do |attribute, limit|
            value = attributes[attribute]
            next if value.nil?

            if value.to_s.length > limit
              raise PolicyStore::ValidationError,
                "#{attribute} exceeds maximum length of #{limit} characters"
            end
          end
        end

        def blank?(value)
          return true if value.nil?
          return value.strip.empty? if value.is_a?(String)

          value.respond_to?(:empty?) && value.empty?
        end

        # `scope_rego` is the form that gets evaluated, so it is always present.
        # `policy_scope` exists only as its source, which is why authoring Rego
        # directly clears it: there is no structured form of a hand-written
        # program, and keeping a stale one would let the two describe different
        # sets of projects.
        def with_compiled_scope(attributes)
          return attributes.merge(policy_scope: nil) unless blank?(attributes[:scope_rego])

          attributes.merge(scope_rego: compiled_scope_rego(attributes[:policy_scope], policy_name: attributes[:name]))
        end

        def with_updated_scope(stored, changes)
          return stored.merge(changes) unless recompile_scope?(stored, changes)

          rego_supplied = changes.key?(:scope_rego) && !blank?(changes[:scope_rego])
          changes = changes.merge(scope_rego: nil) unless rego_supplied

          with_compiled_scope(stored.merge(changes))
        end

        def changes_excluding_restated(stored, changes)
          changes.reject { |attribute, value| stored.key?(attribute) && stored[attribute] == value }
        end

        def recompile_scope?(stored, changes)
          return true if changes.key?(:scope_rego) || !blank?(changes[:policy_scope])
          return false unless changes.key?(:policy_scope) || changes.key?(:name)

          generated_scope_rego?(stored)
        end

        def generated_scope_rego?(stored)
          return true unless blank?(stored[:policy_scope])
          return true if blank?(stored[:scope_rego])

          stored[:scope_rego] == compiled_scope_rego(nil, policy_name: stored[:name])
        end

        def compiled_scope_rego(policy_scope, policy_name:)
          ScopeTranspiler.new(policy_scope, policy_name: policy_name).transpile
        end

        def with_updated_rules(attributes, changes)
          return attributes unless changes.key?(:rules)

          with_compiled_rules(attributes)
        end

        def with_compiled_rules(attributes)
          rules = attributes[:rules] || []

          unless rules.is_a?(Array)
            raise PolicyStore::ValidationError, "rules must be an array of { type, value } entries"
          end

          compiled = rules.each_with_index.map do |rule, index|
            rule.merge('rego' => RuleTranspiler.new(rule, rule_index: index).transpile)
          end

          attributes.merge(rules: compiled)
        end
      end
    end
  end
end

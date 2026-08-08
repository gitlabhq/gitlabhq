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

        # @param _attributes [Hash] the policy attributes
        # @return [Gitlab::PolicyStore::Policy] the created policy
        # @raise [Gitlab::PolicyStore::ValidationError] if required attributes are missing or text limits exceeded
        def create(_attributes)
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
        # @return [Array<Gitlab::PolicyStore::Policy>] the policies
        def list(organization_id:)
          raise NotImplementedError
        end

        private

        def normalize_attributes(attributes)
          attributes.transform_keys(&:to_sym)
        end

        def validate_required_attributes!(attributes)
          missing = REQUIRED_ATTRIBUTES.select { |attr| blank?(attributes[attr]) }
          return if missing.empty?

          raise PolicyStore::ValidationError,
            "Missing required attributes: #{missing.join(', ')}"
        end

        def validate_text_limits!(attributes)
          TEXT_LIMITS.each do |attr, limit|
            value = attributes[attr]
            next if value.nil?

            if value.to_s.length > limit
              raise PolicyStore::ValidationError,
                "#{attr} exceeds maximum length of #{limit} characters"
            end
          end
        end

        def blank?(value)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end

        # `scope_rego` is the form that gets evaluated, so it is always present.
        # `policy_scope` exists only as its source, which is why authoring Rego
        # directly clears it: there is no structured form of a hand-written
        # program, and keeping a stale one would let the two describe different
        # sets of projects.
        def with_compiled_scope(attributes)
          return attributes.merge(policy_scope: nil) unless blank?(attributes[:scope_rego])

          transpiler = ScopeTranspiler.new(attributes[:policy_scope], policy_name: attributes[:name])

          attributes.merge(scope_rego: transpiler.transpile)
        end
      end
    end
  end
end

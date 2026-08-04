# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Ports
      # Contract every storage backend must satisfy. The in-memory adapter
      # implements it today; a future remote (e.g. gRPC) adapter would implement
      # the same interface, keeping the facade and callers unchanged.
      class PolicyRepository
        REQUIRED_ATTRIBUTES = [:organization_id, :name, :trigger_id].freeze

        # @param _attributes [Hash] the policy attributes
        # @return [Gitlab::PolicyStore::Policy] the created policy
        # @raise [Gitlab::PolicyStore::ValidationError] if required attributes are missing
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

        def blank?(value)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end
    end
  end
end

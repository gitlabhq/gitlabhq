# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Ports
      # Contract every evaluation-recording backend must satisfy. Recording is a
      # separate port from PolicyRepository because it serves a different caller:
      # the Policy Engine reporting a completed evaluation, not a management
      # surface editing policies. A future remote adapter implements the same
      # interface, keeping the facade and the engine unchanged.
      class EvaluationRecorder
        TRIGGER_TYPES = Triggers::TYPES
        MODES = PolicyRepository::MODES
        VERDICTS = %w[allow deny require_approval].freeze

        REQUIRED_ATTRIBUTES = %i[
          organization_id policy_id policy_version trigger_type mode verdict evaluated_at
        ].freeze

        RECORDABLE_ATTRIBUTES = (REQUIRED_ATTRIBUTES + %i[project_id environment_id user_id violations]).freeze

        ENUM_ATTRIBUTES = { trigger_type: TRIGGER_TYPES, mode: MODES, verdict: VERDICTS }.freeze
        private_constant :ENUM_ATTRIBUTES

        # Keys allowed on each entry of the violations array. Normalization
        # stringifies nested keys, so these are strings rather than symbols.
        VIOLATION_ATTRIBUTES = %w[details].freeze

        # @param _attributes [Hash] the evaluation, limited to RECORDABLE_ATTRIBUTES;
        #   `trigger_type`, `mode` and `policy_version` are snapshots of the policy at
        #   evaluation time, `violations` is an Array<Hash> each limited to
        #   VIOLATION_ATTRIBUTES
        # @return [Gitlab::PolicyStore::Evaluation] the recorded evaluation with its violations
        # @raise [Gitlab::PolicyStore::ValidationError] if a required attribute is missing,
        #   an attribute is outside RECORDABLE_ATTRIBUTES, an enum value is unknown, or
        #   violations is not an array of permitted-key hashes; persistent adapters also
        #   raise it when a referenced record does not exist
        def record(_attributes)
          raise NotImplementedError
        end

        private

        def recordable_attributes(attributes)
          normalized = normalize_attributes(attributes)

          reject_unknown_attributes!(normalized)
          validate_required_attributes!(normalized)
          validate_enum_attributes!(normalized)
          validate_policy_version!(normalized)
          validate_violations!(normalized)

          normalized.slice(*RECORDABLE_ATTRIBUTES)
        end

        def normalize_attributes(attributes)
          attributes.to_h.transform_keys(&:to_sym).transform_values { |value| JsonValue.deep_stringify(value) }
        end

        def reject_unknown_attributes!(attributes)
          unknown = attributes.keys - RECORDABLE_ATTRIBUTES
          return if unknown.empty?

          raise PolicyStore::ValidationError, "Unknown attributes: #{unknown.join(', ')}"
        end

        def validate_required_attributes!(attributes)
          missing = REQUIRED_ATTRIBUTES.select { |attribute| attributes[attribute].nil? }
          return if missing.empty?

          raise PolicyStore::ValidationError, "Missing required attributes: #{missing.join(', ')}"
        end

        def validate_enum_attributes!(attributes)
          ENUM_ATTRIBUTES.each do |attribute, permitted|
            value = attributes[attribute]
            next if value.nil? || permitted.include?(value)

            raise PolicyStore::ValidationError,
              "#{attribute} must be one of: #{permitted.join(', ')}"
          end
        end

        def validate_policy_version!(attributes)
          version = attributes[:policy_version]
          return if version.nil? || (version.is_a?(Integer) && version.positive?)

          raise PolicyStore::ValidationError, "policy_version must be a positive integer"
        end

        def validate_violations!(attributes)
          violations = attributes[:violations]
          return if violations.nil?

          unless violations.is_a?(Array) && violations.all?(Hash)
            raise PolicyStore::ValidationError, "violations must be an array of { details } entries"
          end

          unknown = violations.flat_map(&:keys).uniq - VIOLATION_ATTRIBUTES
          return if unknown.empty?

          raise PolicyStore::ValidationError, "Unknown violation attributes: #{unknown.join(', ')}"
        end
      end
    end
  end
end

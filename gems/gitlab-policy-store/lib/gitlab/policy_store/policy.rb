# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class Policy
      attr_reader :id, :organization_id, :namespace_id, :name, :description, :version,
        :trigger_type, :rules, :actions, :policy_scope, :scope_rego, :mode,
        :lifecycle_state, :created_at, :updated_at

      # rubocop:disable Metrics/ParameterLists -- value object; one keyword per field
      def initialize(
        id:, organization_id:, name:, trigger_type:, namespace_id: nil, version: 1,
        description: nil, rules: [], actions: [], policy_scope: nil, scope_rego: nil,
        mode: 'enforce', lifecycle_state: 'active', created_at: nil, updated_at: nil)
        # rubocop:enable Metrics/ParameterLists
        @id = id
        @organization_id = organization_id
        @namespace_id = namespace_id
        @name = name
        @description = description
        @version = version
        @trigger_type = trigger_type
        @rules = rules
        @actions = actions
        @policy_scope = policy_scope
        @scope_rego = scope_rego
        @mode = mode
        @lifecycle_state = lifecycle_state
        @created_at = created_at
        @updated_at = updated_at

        freeze
      end

      def to_h
        {
          id: id,
          organization_id: organization_id,
          namespace_id: namespace_id,
          name: name,
          description: description,
          version: version,
          trigger_type: trigger_type,
          rules: rules,
          actions: actions,
          policy_scope: policy_scope,
          scope_rego: scope_rego,
          mode: mode,
          lifecycle_state: lifecycle_state,
          created_at: created_at,
          updated_at: updated_at
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

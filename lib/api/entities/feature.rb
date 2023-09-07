# frozen_string_literal: true

module API
  module Entities
    class Feature < Grape::Entity
      expose :name, documentation: { type: 'string', example: 'experimental_feature' }
      expose :state, documentation: { type: 'string', example: 'off' }
      expose :gates, using: Entities::FeatureGate do |model|
        model.gates.map do |gate|
          # in Flipper 0.26.1, they removed two GateValues#[] method calls for performance reasons
          # https://github.com/flippercloud/flipper/pull/706/commits/ed914b6adc329455a634be843c38db479299efc7
          # https://github.com/flippercloud/flipper/commit/eee20f3ae278d168c8bf70a7a5fcc03bedf432b5
          value = model.gate_values.send(gate.key) # rubocop:disable GitlabSecurity/PublicSend
          # By default all gate values are populated. Only show relevant ones.
          if (value.is_a?(Integer) && value == 0) || (value.is_a?(Set) && value.empty?)
            next
          end

          { key: gate.key, value: value }
        end.compact
      end

      class Definition < Grape::Entity
        ::Feature::Definition::PARAMS.each do |param|
          expose param
        end
      end

      expose :definition, using: Definition do |feature|
        ::Feature::Definition.definitions[feature.name.to_sym]
      end
    end
  end
end

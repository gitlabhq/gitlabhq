# frozen_string_literal: true

module API
  module Entities
    class Feature < Grape::Entity
      expose :name
      expose :state
      expose :gates, using: Entities::FeatureGate do |model|
        model.gates.map do |gate|
          value = model.gate_values[gate.key]

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

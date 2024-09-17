# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class InstanceFeatureFlagsMetric < GenericMetric
          value do
            definitions = ::Feature::Definition.definitions.values.map(&:to_h)
            instance_ffs = Feature.all

            instance_ffs.map do |ff|
              {
                name: ff.name.to_s,
                status: ff.state.to_s,
                type: ff_type(ff, definitions),
                actor_counts: actors(ff)
              }
            end
          end

          private

          def actors(ff)
            ff.gate_values.actors.to_a
              .group_by { |a| a.split(':').first.downcase.pluralize }
              .transform_values!(&:count)
          end

          def ff_type(ff, definitions)
            definition = definitions.find { |d| d[:name] == ff.key }
            definition.present? ? definition[:type] : 'unknown'
          end
        end
      end
    end
  end
end

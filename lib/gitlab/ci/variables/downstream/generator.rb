# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      module Downstream
        class Generator
          Context = Struct.new(:all_bridge_variables, :expand_file_refs, keyword_init: true)

          def initialize(bridge)
            @bridge = bridge

            context = Context.new(all_bridge_variables: bridge.variables, expand_file_refs: false)

            @raw_variable_generator = RawVariableGenerator.new(context)
            @expandable_variable_generator = ExpandableVariableGenerator.new(context)
          end

          def calculate
            calculate_downstream_variables
              .reverse # variables priority
              .uniq { |var| var[:key] } # only one variable key to pass
              .reverse
          end

          private

          attr_reader :bridge, :all_bridge_variables

          def calculate_downstream_variables
            # The order of this list refers to the priority of the variables
            # The variables added later takes priority.
            downstream_yaml_variables +
              downstream_pipeline_dotenv_variables +
              downstream_pipeline_variables +
              downstream_pipeline_schedule_variables
          end

          def downstream_yaml_variables
            return [] unless bridge.forward_yaml_variables?

            build_downstream_variables_from(bridge.yaml_variables)
          end

          def downstream_pipeline_variables
            return [] unless bridge.forward_pipeline_variables?

            pipeline_variables = bridge.pipeline_variables.to_a
            build_downstream_variables_from(pipeline_variables)
          end

          def downstream_pipeline_schedule_variables
            return [] unless bridge.forward_pipeline_variables?

            pipeline_schedule_variables = bridge.pipeline_schedule_variables.to_a
            build_downstream_variables_from(pipeline_schedule_variables)
          end

          def downstream_pipeline_dotenv_variables
            return [] unless bridge.forward_pipeline_variables?

            pipeline_dotenv_variables = bridge.dependency_variables.to_a
            build_downstream_variables_from(pipeline_dotenv_variables)
          end

          def build_downstream_variables_from(variables)
            Gitlab::Ci::Variables::Collection.fabricate(variables).flat_map do |item|
              if item.raw?
                @raw_variable_generator.for(item)
              else
                @expandable_variable_generator.for(item)
              end
            end
          end
        end
      end
    end
  end
end

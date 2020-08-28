# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Normalizer
        class MatrixStrategy
          class << self
            def applies_to?(config)
              config.is_a?(Hash) && config.key?(:matrix)
            end

            def build_from(job_name, initial_config)
              config = expand(initial_config[:matrix])
              total = config.size

              config.map.with_index do |vars, index|
                new(job_name, index.next, vars, total)
              end
            end

            # rubocop: disable CodeReuse/ActiveRecord
            def expand(config)
              config.flat_map do |config|
                values = config.values

                values[0]
                  .product(*values.from(1))
                  .map { |vals| config.keys.zip(vals).to_h }
              end
            end
            # rubocop: enable CodeReuse/ActiveRecord
          end

          def initialize(job_name, instance, variables, total)
            @job_name = job_name
            @instance = instance
            @variables = variables.to_h
            @total = total
          end

          def attributes
            {
              name: name,
              instance: instance,
              variables: variables,
              parallel: { total: total }
            }
          end

          def name
            if Gitlab::Ci::Features.new_matrix_job_names_enabled?
              name_with_variable_details
            else
              old_name
            end
          end

          private

          def name_with_variable_details
            vars = variables
              .values
              .compact
              .join(', ')

            "#{job_name}: [#{vars}]"
          end

          def old_name
            "#{job_name} #{instance}/#{total}"
          end

          attr_reader :job_name, :instance, :variables, :total
        end
      end
    end
  end
end

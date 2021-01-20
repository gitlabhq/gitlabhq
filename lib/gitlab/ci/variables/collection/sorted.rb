# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Collection
        class Sorted
          include TSort
          include Gitlab::Utils::StrongMemoize

          def initialize(variables)
            @variables = variables
          end

          def valid?
            errors.nil?
          end

          # errors sorts an array of variables, ignoring unknown variable references,
          # and returning an error string if a circular variable reference is found
          def errors
            return if Feature.disabled?(:variable_inside_variable)

            strong_memoize(:errors) do
              # Check for cyclic dependencies and build error message in that case
              errors = each_strongly_connected_component.filter_map do |component|
                component.map { |v| v[:key] }.inspect if component.size > 1
              end

              "circular variable reference detected: #{errors.join(', ')}" if errors.any?
            end
          end

          # sort sorts an array of variables, ignoring unknown variable references.
          # If a circular variable reference is found, the original array is returned
          def sort
            return @variables if Feature.disabled?(:variable_inside_variable)
            return @variables if errors

            tsort
          end

          private

          def tsort_each_node(&block)
            @variables.each(&block)
          end

          def tsort_each_child(variable, &block)
            each_variable_reference(variable[:value], &block)
          end

          def input_vars
            strong_memoize(:input_vars) do
              @variables.index_by { |env| env.fetch(:key) }
            end
          end

          def walk_references(value)
            return unless ExpandVariables.possible_var_reference?(value)

            value.scan(ExpandVariables::VARIABLES_REGEXP) do |var_ref|
              yield(input_vars, var_ref.first)
            end
          end

          def each_variable_reference(value)
            walk_references(value) do |vars_hash, ref_var_name|
              variable = vars_hash.dig(ref_var_name)
              yield variable if variable
            end
          end
        end
      end
    end
  end
end

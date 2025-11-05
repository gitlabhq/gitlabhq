# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        class Inputs
          class Validator
            RULE_EXPRESSION_STATEMENT = :if

            def initialize(entries)
              @entries = entries
            end

            def validate!
              validate_undefined_input_references
              validate_circular_dependencies
            end

            private

            attr_reader :entries

            def validate_undefined_input_references
              defined_inputs = entries.keys.map(&:to_s)

              entries.each do |name, input|
                next unless input.input_rules

                input.input_rules.each_with_index do |rule, idx|
                  validate_rule_references(name, rule, idx, defined_inputs)
                end
              end
            end

            def validate_rule_references(input_name, rule, rule_index, defined_inputs)
              return unless rule[RULE_EXPRESSION_STATEMENT]

              referenced_inputs = extract_input_names_from(rule[RULE_EXPRESSION_STATEMENT])
              return unless referenced_inputs

              undefined_inputs = referenced_inputs - defined_inputs
              return if undefined_inputs.empty?

              entries[input_name].validator.errors.add(
                :config,
                "rule[#{rule_index}] references undefined inputs: #{undefined_inputs.join(', ')}"
              )
            end

            def validate_circular_dependencies
              dependency_graph = build_dependency_graph
              Gitlab::Ci::YamlProcessor::Dag.check_circular_dependencies!(dependency_graph)
            rescue Gitlab::Ci::YamlProcessor::ValidationError
              first_input = entries.each_key.first
              errors = entries[first_input].validator.errors

              return if errors.full_messages.any? { |msg| msg.include?("circular dependency detected") }

              errors.add(:config, "circular dependency detected")
            end

            def build_dependency_graph
              entries.transform_keys(&:to_s).transform_values do |input|
                get_input_dependencies(input)
              end
            end

            def get_input_dependencies(input)
              return [] unless input.input_rules

              input.input_rules.flat_map do |rule|
                next [] unless rule[RULE_EXPRESSION_STATEMENT]

                (extract_input_names_from(rule[RULE_EXPRESSION_STATEMENT]) || []).map(&:to_s)
              end
            end

            def extract_input_names_from(if_clause)
              @parsed_expressions ||= {}
              @parsed_expressions[if_clause] ||= begin
                statement = Gitlab::Ci::Pipeline::Expression::Statement.new(if_clause)
                statement.input_names
              rescue Gitlab::Ci::Pipeline::Expression::Statement::StatementError
                # Invalid expressions are caught by Rule entry validation
                nil
              end
            end
          end
        end
      end
    end
  end
end

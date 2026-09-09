# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class RuleTranspiler
      module Emitters
        class Environment < Base
          def environment_statements
            conditions = environment_conditions

            invalid!("environment rule requires at least one of names or tiers") if conditions.empty?

            [violation_rule(details: environment_details, conditions: conditions + [environment_message])]
          end

          private

          # `rule_index` rides on the violation rather than only on the header comment
          # because `violation` is a set: once a policy's programs are combined into one
          # module, two rules emitting identical objects would deduplicate into one.
          def environment_details
            fields = [
              %("rule_index": #{rule_index}),
              %("environment_id": input.environment.id),
              %("environment_name": input.environment.name)
            ]

            "{#{fields.join(', ')}}"
          end

          def environment_conditions
            conditions = []
            conditions << "input.environment.name in #{rego_set(environment_names)}" if environment_names.any?
            conditions << "input.environment.tier in #{rego_set(environment_tiers)}" if environment_tiers.any?

            conditions
          end

          def environment_message
            'msg := sprintf("deployment to %s is blocked by this policy", [input.environment.name])'
          end

          def environment_names
            @environment_names ||= sorted_unique_strings_from(configuration["names"])
          end

          def environment_tiers
            @environment_tiers ||= sorted_unique_strings_from(configuration["tiers"])
          end
        end
      end
    end
  end
end

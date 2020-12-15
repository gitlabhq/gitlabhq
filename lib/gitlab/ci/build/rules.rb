# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules
        include ::Gitlab::Utils::StrongMemoize

        Result = Struct.new(:when, :start_in, :allow_failure, :variables) do
          def build_attributes(seed_attributes = {})
            {
              when: self.when,
              options: { start_in: start_in }.compact,
              allow_failure: allow_failure,
              yaml_variables: yaml_variables(seed_attributes[:yaml_variables])
            }.compact
          end

          def pass?
            self.when != 'never'
          end

          private

          def yaml_variables(seed_variables)
            return unless variables && seed_variables

            indexed_seed_variables = seed_variables.deep_dup.index_by { |var| var[:key] }

            variables.each_with_object(indexed_seed_variables) do |var, hash|
              hash[var[0].to_s] = { key: var[0].to_s, value: var[1], public: true }
            end.values
          end
        end

        def initialize(rule_hashes, default_when:)
          @rule_list    = Rule.fabricate_list(rule_hashes)
          @default_when = default_when
        end

        def evaluate(pipeline, context)
          if @rule_list.nil?
            Result.new(@default_when)
          elsif matched_rule = match_rule(pipeline, context)
            Result.new(
              matched_rule.attributes[:when] || @default_when,
              matched_rule.attributes[:start_in],
              matched_rule.attributes[:allow_failure],
              matched_rule.attributes[:variables]
            )
          else
            Result.new('never')
          end
        end

        private

        def match_rule(pipeline, context)
          @rule_list.find { |rule| rule.matches?(pipeline, context) }
        end
      end
    end
  end
end

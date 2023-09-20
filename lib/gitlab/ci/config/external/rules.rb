# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Rules
          InvalidIncludeRulesError = Class.new(Mapper::Error)

          def initialize(rule_hashes)
            return unless rule_hashes

            # We must compose the include rules entry here because included
            # files are expanded before `@root.compose!` runs in Ci::Config.
            rules_entry = Entry::Include::Rules.new(rule_hashes)
            rules_entry.compose!

            raise InvalidIncludeRulesError, "include:#{rules_entry.errors.first}" unless rules_entry.valid?

            @rule_list = Build::Rules::Rule.fabricate_list(rules_entry.value)
          end

          def evaluate(context)
            if @rule_list.nil?
              Result.new('always')
            elsif matched_rule = match_rule(context)
              Result.new(matched_rule.attributes[:when])
            else
              Result.new('never')
            end
          rescue Build::Rules::Rule::Clause::ParseError => e
            raise InvalidIncludeRulesError, "include:#{e.message}"
          end

          private

          def match_rule(context)
            @rule_list.find { |rule| rule.matches?(context.pipeline, context) }
          end

          Result = Struct.new(:when) do
            def pass?
              self.when != 'never'
            end
          end
        end
      end
    end
  end
end

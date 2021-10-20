# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Rules
          ALLOWED_KEYS = Entry::Include::Rules::Rule::ALLOWED_KEYS

          InvalidIncludeRulesError = Class.new(Mapper::Error)

          def initialize(rule_hashes)
            validate(rule_hashes)

            @rule_list = Build::Rules::Rule.fabricate_list(rule_hashes)
          end

          def evaluate(context)
            Result.new(@rule_list.nil? || match_rule(context))
          end

          private

          def match_rule(context)
            @rule_list.find { |rule| rule.matches?(nil, context) }
          end

          def validate(rule_hashes)
            return unless rule_hashes.is_a?(Array)

            rule_hashes.each do |rule_hash|
              next if (rule_hash.keys - ALLOWED_KEYS).empty?

              raise InvalidIncludeRulesError, "invalid include rule: #{rule_hash}"
            end
          end

          Result = Struct.new(:result) do
            def pass?
              !!result
            end
          end
        end
      end
    end
  end
end

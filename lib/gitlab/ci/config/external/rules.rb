# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Rules
          def initialize(rule_hashes)
            @rule_list = Build::Rules::Rule.fabricate_list(rule_hashes)
          end

          def evaluate(context)
            Result.new(@rule_list.nil? || match_rule(context))
          end

          private

          def match_rule(context)
            @rule_list.find { |rule| rule.matches?(nil, context) }
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

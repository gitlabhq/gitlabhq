# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class RuleProgramMerger
      include RegoPackage

      def initialize(rules)
        @rules = rules
      end

      def merge
        raise PolicyStore::Error, "rules must be an array of compiled entries" unless rules.is_a?(Array)
        return nil if rules.empty?

        bodies = rules.map.with_index do |rule, index|
          rego = rule.is_a?(Hash) ? rule["rego"] : nil
          unless rego.is_a?(String) && !rego.empty?
            raise PolicyStore::Error, "rule #{index} has no compiled rego to merge"
          end

          ensure_trailing_newline(strip_declaration(rego))
        end

        "#{RULE_PRELUDE}\n#{bodies.join}"
      end

      private

      attr_reader :rules

      def ensure_trailing_newline(text)
        return text if text.empty? || text.end_with?("\n")

        "#{text}\n"
      end
    end
  end
end

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

        # Rego allows imports only ahead of the first rule.
        # Lift every rule's imports into the shared header so the merged module parses.
        imports = []
        bodies = rules.map.with_index do |rule, index|
          rego = rule.is_a?(Hash) ? rule["rego"] : nil
          unless rego.is_a?(String) && !rego.empty?
            raise PolicyStore::Error, "rule #{index} has no compiled rego to merge"
          end

          body, rule_imports = split_header(rego)
          imports.concat(rule_imports)

          ensure_trailing_newline(body)
        end

        "#{header(imports)}#{bodies.join}"
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

# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module RegoPackage
      extend self

      PACKAGE_NAME = "governance"

      RULE_PRELUDE = "package #{PACKAGE_NAME}".freeze

      DECLARATION_PATTERN = /\Apackage[ \t]+(\S+)\z/

      def declared_in(rego_source)
        index, lines = first_statement_index(rego_source)
        return nil unless index

        statement_in(lines[index])[DECLARATION_PATTERN, 1]
      end

      def strip_declaration(rego_source)
        index, lines = first_statement_index(rego_source)

        return rego_source unless index && statement_in(lines[index]).match?(DECLARATION_PATTERN)

        lines.delete_at(index)
        lines.join
      end

      private

      def first_statement_index(rego_source)
        lines = rego_source.each_line.to_a
        index = lines.index { |line| !statement_in(line).empty? }

        [index, lines]
      end

      def statement_in(line)
        line.sub(/#.*/, "").strip
      end
    end
  end
end

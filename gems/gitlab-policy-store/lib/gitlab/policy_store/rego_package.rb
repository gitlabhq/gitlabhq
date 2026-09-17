# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module RegoPackage
      extend self

      PACKAGE_NAME = "governance"

      RULE_PRELUDE = "package #{PACKAGE_NAME}".freeze

      DECLARATION_PATTERN = /\Apackage[ \t]+(\S+)\z/

      IMPORT_PATTERN = /\Aimport\s/

      def declared_in(rego_source)
        index, lines = first_statement_index(rego_source)
        return nil unless index

        statement_in(lines[index])[DECLARATION_PATTERN, 1]
      end

      # Splits a program into its body and its header lines in one walk: the leading package
      # declaration is dropped, imports are collected without their comments, and the walk
      # stops at the first rule so nothing below it is touched.
      #
      # @return [Array(String, Array<String>)] the body and the import statements
      def split_header(rego_source)
        imports = []
        lines = rego_source.each_line.to_a
        seen_statement = false

        lines.each_with_index do |line, index|
          statement = statement_in(line)
          next if statement.empty?

          if !seen_statement && statement.match?(DECLARATION_PATTERN)
            lines[index] = nil
          elsif statement.match?(IMPORT_PATTERN)
            imports << statement
            lines[index] = nil
          else
            break
          end

          seen_statement = true
        end

        [lines.compact.join, imports]
      end

      # Renders the header `split_header` reads: the package line, then one copy of each
      # import statement, since the engine rejects a repeated import as shadowed.
      #
      # @return [String]
      def header(imports)
        return "#{RULE_PRELUDE}\n" if imports.empty?

        "#{RULE_PRELUDE}\n\n#{imports.uniq.join("\n")}\n"
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

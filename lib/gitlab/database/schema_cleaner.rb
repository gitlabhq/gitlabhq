# frozen_string_literal: true

module Gitlab
  module Database
    class SchemaCleaner
      attr_reader :original_schema

      def initialize(original_schema)
        @original_schema = original_schema
      end

      def clean(io)
        structure = original_schema.dup

        # Remove noise
        structure.gsub!(/^COMMENT ON EXTENSION.*/, '')
        structure.gsub!(/^SET.+/, '')
        structure.gsub!(/^SELECT pg_catalog\.set_config\('search_path'.+/, '')
        structure.gsub!(/^--.*/, "\n")

        structure = "SET search_path=public;\n" + structure

        structure.gsub!(/\n{3,}/, "\n\n")

        io << structure

        nil
      end
    end
  end
end

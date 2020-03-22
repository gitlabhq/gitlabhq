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

        # Postgres compat fix for PG 9.6 (which doesn't support (AS datatype) syntax for sequences)
        structure.gsub!(/CREATE SEQUENCE [^.]+\.\S+\n(\s+AS integer\n)/) { |m| m.gsub(Regexp.last_match[1], '') }

        # Also a PG 9.6 compatibility fix, see below.
        structure.gsub!(/^CREATE EXTENSION IF NOT EXISTS plpgsql.*/, '')
        structure.gsub!(/^COMMENT ON EXTENSION.*/, '')

        # Remove noise
        structure.gsub!(/^SET.+/, '')
        structure.gsub!(/^SELECT pg_catalog\.set_config\('search_path'.+/, '')
        structure.gsub!(/^--.*/, "\n")
        structure.gsub!(/\n{3,}/, "\n\n")

        io << "SET search_path=public;\n\n"

        # Adding plpgsql explicitly is again a compatibility fix for PG 9.6
        # In more recent versions of pg_dump, the extension isn't explicitly dumped anymore.
        # We use PG 9.6 still on CI and for schema checks - here this is still the case.
        io << <<~SQL.strip
          CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
        SQL

        io << structure

        nil
      end
    end
  end
end

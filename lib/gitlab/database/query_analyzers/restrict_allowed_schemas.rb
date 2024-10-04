# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class RestrictAllowedSchemas < Base
        UnsupportedSchemaError = Class.new(QueryAnalyzerError)
        DDLNotAllowedError = Class.new(UnsupportedSchemaError)
        DMLNotAllowedError = Class.new(UnsupportedSchemaError)
        DMLAccessDeniedError = Class.new(UnsupportedSchemaError)

        # Re-map schemas observed schemas to a single cluster mode
        # - symbol:
        #     The mapped schema indicates that it contains all data in a single-cluster mode
        # - nil:
        #     Inidicates that changes made to this schema are ignored and always allowed
        SCHEMA_MAPPING = {
          gitlab_shared: nil,
          gitlab_internal: nil,

          # Pods specific changes
          gitlab_main_clusterwide: :gitlab_main,
          gitlab_main_cell: :gitlab_main
        }.freeze

        class << self
          def enabled?
            true
          end

          def allowed_gitlab_schemas
            self.context[:allowed_gitlab_schemas]
          end

          def allowed_gitlab_schemas=(value)
            self.context[:allowed_gitlab_schemas] = value
          end

          def analyze(parsed)
            # This analyzer requires the PgQuery parsed query to be present
            return unless parsed.pg

            # If list of schemas is empty, we allow only DDL changes
            if self.dml_mode?
              self.restrict_to_dml_only(parsed)
            else
              self.restrict_to_ddl_only(parsed)
            end
          end

          def require_ddl_mode!(message = "")
            return unless self.context

            self.raise_dml_not_allowed_error(message) if self.dml_mode?
          end

          def require_dml_mode!(message = "")
            return unless self.context

            self.raise_ddl_not_allowed_error(message) if self.ddl_mode?
          end

          private

          def restrict_to_ddl_only(parsed)
            tables = self.dml_tables(parsed)
            schemas = self.dml_schemas(tables)
            schemas = self.map_schemas(schemas)

            if schemas.any?
              self.raise_dml_not_allowed_error("Modifying of '#{tables}' (#{schemas.to_a}) with '#{parsed.sql}'")
            end
          end

          def restrict_to_dml_only(parsed)
            if parsed.pg.ddl_tables.any?
              self.raise_ddl_not_allowed_error("Modifying of '#{parsed.pg.ddl_tables}' with '#{parsed.sql}'")
            end

            if parsed.pg.ddl_functions.any?
              self.raise_ddl_not_allowed_error("Modifying of '#{parsed.pg.ddl_functions}' with '#{parsed.sql}'")
            end

            tables = self.dml_tables(parsed)
            schemas = self.dml_schemas(tables)
            schemas = self.map_schemas(schemas)
            allowed_schemas = self.map_schemas(self.allowed_gitlab_schemas)

            if (schemas - allowed_schemas).any?
              raise DMLAccessDeniedError, \
                "Select/DML queries (SELECT/UPDATE/DELETE) do access '#{tables}' (#{schemas.to_a}) " \
                "which is outside of list of allowed schemas: '#{self.allowed_gitlab_schemas}'. " \
                "#{documentation_url}"
            end
          end

          def dml_mode?
            self.allowed_gitlab_schemas&.any?
          end

          def ddl_mode?
            !self.dml_mode?
          end

          # There is a special case where CREATE VIEW DDL statement can include DML statements.
          # For this case, +select_tables+ should be empty, to avoid false positives.
          #
          # @example
          #          CREATE VIEW issues AS SELECT * FROM tickets
          def dml_tables(parsed)
            select_tables = self.dml_from_create_view?(parsed) ? [] : parsed.pg.select_tables

            select_tables + parsed.pg.dml_tables
          end

          def dml_from_create_view?(parsed)
            return unless ddl_mode?

            QueryAnalyzerHelpers.dml_from_create_view?(parsed)
          end

          def dml_schemas(tables)
            ::Gitlab::Database::GitlabSchema.table_schemas!(tables)
          end

          def map_schemas(schemas)
            schemas = schemas.to_set

            SCHEMA_MAPPING.each do |in_schema, mapped_schema|
              next unless schemas.delete?(in_schema)

              schemas.add(mapped_schema) if mapped_schema
            end

            schemas
          end

          def raise_dml_not_allowed_error(message)
            raise DMLNotAllowedError, \
              "Select/DML queries (SELECT/UPDATE/DELETE) are disallowed in the DDL (structure) mode. " \
              "#{message}. #{documentation_url}" \
          end

          def raise_ddl_not_allowed_error(message)
            raise DDLNotAllowedError, \
              "DDL queries (structure) are disallowed in the Select/DML (SELECT/UPDATE/DELETE) mode. " \
              "#{message}. #{documentation_url}"
          end

          def documentation_url
            "For more information visit: https://docs.gitlab.com/ee/development/database/migrations_for_multiple_databases.html"
          end
        end
      end
    end
  end
end

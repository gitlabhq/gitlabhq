# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      # The purpose of this analyzer is to validate if tables observed
      # are properly used according to schema used by current connection
      class GitlabSchemasValidateConnection < Base
        CrossSchemaAccessError = Class.new(QueryAnalyzerError)

        class << self
          def enabled?
            true
          end

          # There is a special case where CREATE VIEW DDL statement can include DML statements.
          # For this case, +select_tables+ should be empty, to keep the schema consistent between +main+ and +ci+.
          #
          # @example
          #          CREATE VIEW issues AS SELECT * FROM tickets
          def analyze(parsed)
            # This analyzer requires the PgQuery parsed query to be present
            return unless parsed.pg

            select_tables = QueryAnalyzerHelpers.dml_from_create_view?(parsed) ? [] : parsed.pg.select_tables
            tables = select_tables + parsed.pg.dml_tables
            table_schemas = ::Gitlab::Database::GitlabSchema.table_schemas!(tables)
            return if table_schemas.empty?

            allowed_schemas = ::Gitlab::Database.gitlab_schemas_for_connection(parsed.connection)
            return unless allowed_schemas

            invalid_schemas = table_schemas - allowed_schemas

            return if invalid_schemas.empty?

            schema_list = table_schemas.sort.join(',')

            message = "The query tried to access #{tables} (of #{schema_list}) "
            message += "which is outside of allowed schemas (#{allowed_schemas}) "
            message += "for the current connection '#{Gitlab::Database.db_config_name(parsed.connection)}'"

            raise CrossSchemaAccessError, message
          end
        end
      end
    end
  end
end

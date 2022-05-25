# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module RestrictGitlabSchema
        extend ActiveSupport::Concern

        included do
          class_attribute :allowed_gitlab_schemas
        end

        class_methods do
          def restrict_gitlab_migration(gitlab_schema:)
            unless Gitlab::Database::GitlabSchema.schema_names.include?(gitlab_schema)
              raise "Unknown 'gitlab_schema: #{gitlab_schema}' specified. It needs to be one of: " \
                "#{Gitlab::Database::GitlabSchema.schema_names.to_a}"
            end

            self.allowed_gitlab_schemas = [gitlab_schema]
          end
        end

        def exec_migration(conn, direction)
          if unmatched_schemas.any?
            migration_skipped
            return
          end

          Gitlab::Database::QueryAnalyzer.instance.within([validator_class, connection_validator_class]) do
            validator_class.allowed_gitlab_schemas = self.allowed_gitlab_schemas

            super
          end
        end

        private

        def migration_skipped
          say "The migration is skipped since it modifies the schemas: #{self.class.allowed_gitlab_schemas}."
          say "This database can only apply migrations in one of the following schemas: " \
            "#{allowed_schemas_for_connection}."
        end

        def validator_class
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas
        end

        def connection_validator_class
          Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection
        end

        def unmatched_schemas
          (self.allowed_gitlab_schemas || []) - allowed_schemas_for_connection
        end

        def allowed_schemas_for_connection
          Gitlab::Database.gitlab_schemas_for_connection(connection)
        end
      end
    end
  end
end

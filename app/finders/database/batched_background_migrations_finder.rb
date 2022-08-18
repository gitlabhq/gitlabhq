# frozen_string_literal: true

module Database
  class BatchedBackgroundMigrationsFinder
    RETURNED_MIGRATIONS = 20

    def initialize(connection:)
      @connection = connection
    end

    def execute
      batched_migration_class.ordered_by_created_at_desc.for_gitlab_schema(schema).limit(RETURNED_MIGRATIONS)
    end

    private

    attr_accessor :connection

    def batched_migration_class
      Gitlab::Database::BackgroundMigration::BatchedMigration
    end

    def schema
      Gitlab::Database.gitlab_schemas_for_connection(connection)
    end
  end
end

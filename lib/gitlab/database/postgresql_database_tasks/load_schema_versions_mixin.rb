# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlDatabaseTasks
      module LoadSchemaVersionsMixin
        extend ActiveSupport::Concern

        def structure_load(...)
          super(...)

          Gitlab::Database::SchemaMigrations.load_all(
            ActiveRecord::Tasks::DatabaseTasks.migration_connection
          )
        end
      end
    end
  end
end

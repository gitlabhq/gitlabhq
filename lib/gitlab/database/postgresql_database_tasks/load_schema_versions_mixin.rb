# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlDatabaseTasks
      module LoadSchemaVersionsMixin
        extend ActiveSupport::Concern

        def structure_load(*args)
          super(*args)
          Gitlab::Database::SchemaVersionFiles.load_all
        end
      end
    end
  end
end

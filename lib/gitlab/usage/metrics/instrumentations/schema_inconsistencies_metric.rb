# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class SchemaInconsistenciesMetric < GenericMetric
          MAX_INCONSISTENCIES = 150 # Limit the number of inconsistencies reported to avoid large payloads

          value do
            runner = Gitlab::Database::SchemaValidation::Runner.new(structure_sql, database)

            inconsistencies = runner.execute

            inconsistencies.take(MAX_INCONSISTENCIES).map do |inconsistency|
              {
                object_name: inconsistency.object_name,
                inconsistency_type: inconsistency.type,
                object_type: inconsistency.object_type
              }
            end
          end

          class << self
            private

            def database
              database_model = Gitlab::Database.database_base_models[Gitlab::Database::MAIN_DATABASE_NAME]
              Gitlab::Database::SchemaValidation::Database.new(database_model.connection)
            end

            def structure_sql
              stucture_sql_path = Rails.root.join('db/structure.sql')
              Gitlab::Database::SchemaValidation::StructureSql.new(stucture_sql_path)
            end
          end
        end
      end
    end
  end
end

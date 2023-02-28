# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class IndexInconsistenciesMetric < GenericMetric
          value do
            runner = Gitlab::Database::SchemaValidation::Runner.new(structure_sql, database, validators: validators)

            inconsistencies = runner.execute

            inconsistencies.map do |inconsistency|
              {
                object_name: inconsistency.object_name,
                inconsistency_type: inconsistency.type
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

            def validators
              [
                Gitlab::Database::SchemaValidation::Validators::MissingIndexes,
                Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionIndexes,
                Gitlab::Database::SchemaValidation::Validators::ExtraIndexes
              ]
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class IndexInconsistenciesMetric < GenericMetric
          value do
            runner = Gitlab::Schema::Validation::Runner.new(structure_sql, database, validators: validators)

            inconsistencies = runner.execute

            inconsistencies.map do |inconsistency|
              {
                object_name: inconsistency.object_name,
                inconsistency_type: inconsistency.type
              }
            end
          end

          private

          def database
            database_model = Gitlab::Database.database_base_models[Gitlab::Database::MAIN_DATABASE_NAME]
            Gitlab::Schema::Validation::Sources::Database.new(database_model.connection)
          end

          def structure_sql
            stucture_sql_path = Rails.root.join('db/structure.sql')
            Gitlab::Schema::Validation::Sources::StructureSql.new(stucture_sql_path)
          end

          def validators
            [
              Gitlab::Schema::Validation::Validators::MissingIndexes,
              Gitlab::Schema::Validation::Validators::DifferentDefinitionIndexes,
              Gitlab::Schema::Validation::Validators::ExtraIndexes
            ]
          end
        end
      end
    end
  end
end

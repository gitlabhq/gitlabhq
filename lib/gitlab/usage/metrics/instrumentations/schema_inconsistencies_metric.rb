# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class SchemaInconsistenciesMetric < GenericMetric
          include Gitlab::Database::ReplicaFallback

          MAX_INCONSISTENCIES = 150 # Limit the number of inconsistencies reported to avoid large payloads

          value do
            runner = Gitlab::Schema::Validation::Runner.new(structure_sql, database, validators: validators)

            inconsistencies = with_replica_fallback(database_model) { runner.execute }

            inconsistencies.take(MAX_INCONSISTENCIES).map do |inconsistency|
              {
                object_name: inconsistency.object_name,
                inconsistency_type: inconsistency.type,
                object_type: inconsistency.object_type
              }
            end
          end

          private

          def validators
            Gitlab::Schema::Validation::Validators::Base.all_validators
          end

          def database
            Gitlab::Schema::Validation::Sources::Database.new(database_model.connection)
          end

          def database_model
            Gitlab::Database.database_base_models[Gitlab::Database::MAIN_DATABASE_NAME]
          end

          def structure_sql
            stucture_sql_path = Rails.root.join('db/structure.sql')
            Gitlab::Schema::Validation::Sources::StructureSql.new(stucture_sql_path)
          end
        end
      end
    end
  end
end

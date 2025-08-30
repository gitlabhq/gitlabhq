# frozen_string_literal: true

module Gitlab
  module Database
    class SchemaChecker
      def initialize(database_name:)
        @structure_sql_path = Rails.root.join('db/structure.sql')
        @database_name = database_name
        @database_model = Gitlab::Database.database_base_models[database_name]

        raise "Invalid database name: #{database_name}" unless database_model

        @database = Gitlab::Schema::Validation::Sources::Database.new(database_model.connection)
        @structure_sql = Gitlab::Schema::Validation::Sources::StructureSql.new(structure_sql_path)
        @validators = {
          missing_tables: Gitlab::Schema::Validation::Validators::MissingTables,
          missing_indexes: Gitlab::Schema::Validation::Validators::MissingIndexes,
          missing_foreign_keys: Gitlab::Schema::Validation::Validators::MissingForeignKeys,
          missing_sequences: Gitlab::Schema::Validation::Validators::MissingSequences,
          wrong_sequence_owners: Gitlab::Schema::Validation::Validators::DifferentSequenceOwners
        }
      end

      def execute
        check_inconsistencies
      end

      private

      attr_reader :database_name, :database_model, :structure_sql_path, :database, :structure_sql, :validators

      def check_inconsistencies
        schema_check_results = {}

        validators.each do |key, validator|
          inconsistencies = validator.new(structure_sql, database).execute
          schema_check_results[key] = format_inconsistencies(inconsistencies)
        end

        {
          schema_check_results: { database_name => schema_check_results },
          metadata: {
            last_run_at: Time.current.iso8601
          }
        }
      end

      def format_inconsistencies(inconsistencies)
        inconsistencies.map do |entry|
          base_entry = { name: entry.object_name }
          base_entry[:details] = entry.details if entry.details.present?
          base_entry
        end
      end
    end
  end
end

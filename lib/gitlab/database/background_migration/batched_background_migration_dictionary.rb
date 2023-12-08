# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedBackgroundMigrationDictionary
        def self.entry(migration_job_name)
          entries_by_migration_job_name[migration_job_name]
        end

        private_class_method def self.entries_by_migration_job_name
          @entries_by_migration_job_name ||= Dir.glob(dict_path).to_h do |file_path|
            entry = Entry.new(file_path)
            [entry.migration_job_name, entry]
          end
        end

        private_class_method def self.dict_path
          Rails.root.join('db/docs/batched_background_migrations/*.yml')
        end

        class Entry
          def initialize(file_path)
            @file_path = file_path
            @data = YAML.load_file(file_path)
          end

          def migration_job_name
            data['migration_job_name']
          end

          def finalized_by
            data['finalized_by']
          end

          private

          attr_reader :file_path, :data
        end
      end
    end
  end
end

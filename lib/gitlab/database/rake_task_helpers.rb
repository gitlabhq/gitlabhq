# frozen_string_literal: true

module Gitlab
  module Database
    class RakeTaskHelpers
      TASK_MAPPING = {
        redo: [:down, :up],
        up: :up,
        down: :down
      }.with_indifferent_access.freeze

      class << self
        def execute_migration_task(task)
          with_single_dump do
            rails_tasks_for(task).each do |rails_task|
              for_each_database do |db_name|
                Rake::Task["db:migrate:#{rails_task}:#{db_name}"].invoke
              end
            end
          end
        end

        private

        def for_each_database
          ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |db_name|
            yield db_name
          end
        end

        def with_single_dump
          old_value = ActiveRecord.dump_schema_after_migration
          ActiveRecord.dump_schema_after_migration = false

          yield

          ActiveRecord.dump_schema_after_migration = true

          Rake::Task['db:_dump'].invoke
        ensure
          ActiveRecord.dump_schema_after_migration = old_value
        end

        def databases
          @databases ||= ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml
        end

        def rails_tasks_for(task)
          rails_tasks = TASK_MAPPING.fetch(task) { raise 'Unknown task!' }

          Array.wrap(rails_tasks)
        end
      end
    end
  end
end

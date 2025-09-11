# frozen_string_literal: true

namespace :db do
  namespace :migrate do
    %i[redo up down].each do |task_name|
      desc "Runs the regular `#{task}` task for all databases"
      task "#{task_name}_all": :load_config do
        Gitlab::Database::RakeTaskHelpers.execute_migration_task(task_name)
      end
    end
  end
end

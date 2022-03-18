# frozen_string_literal: true

if Rails::VERSION::MAJOR >= 7
  raise "Remove `#{__FILE__}`. This is backport of `database_tasks:` Rails 7.x feature."
end

# This backports `database_tasks:` feature to skip running migrations for some databases
# PR: https://github.com/rails/rails/pull/42794/files

module DatabaseTasks
  module ActiveRecordDatabaseConfigurations
    def configs_for(env_name: nil, name: nil, include_replicas: false)
      configs = super

      unless include_replicas
        if name
          configs = nil unless configs&.database_tasks?
        else
          configs = configs.select do |db_config|
            db_config.database_tasks?
          end
        end
      end

      configs
    end
  end

  module ActiveRecordDatabaseConfigurationsHashConfig
    def database_tasks? # :nodoc:
      !replica? && !!configuration_hash.fetch(:database_tasks, true)
    end
  end
end

ActiveRecord::DatabaseConfigurations.prepend(DatabaseTasks::ActiveRecordDatabaseConfigurations)
ActiveRecord::DatabaseConfigurations::HashConfig.prepend(DatabaseTasks::ActiveRecordDatabaseConfigurationsHashConfig)

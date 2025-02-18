# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Services
        # Holds all database information necessary to initialize individual connections
        # It handles both single and decomposed databases
        class Postgres
          include Enumerable
          attr_reader :context

          def initialize(context)
            @context = context
          end

          # Iterator for configured databases
          #
          # @return [Enumerator, Array<Database>]
          def each
            return enum_for(__method__) unless block_given?

            entries.each do |item|
              yield(item)
            end
          end

          # All unique configured databases (excluding hidden/partitions)
          def entries
            return @entries if defined?(@entries)

            @entries = database_configurations.map do |config|
              Database.new(config)
            end
          end

          # @return [Database]
          def main_database
            each do |database|
              return database if database.connection_name == 'main'
            end

            raise Gitlab::Backup::Cli::Errors::DatabaseMissingConnectionError, 'main'
          end

          private

          # Return ActiveRecord parsed database configurations object
          #
          # @return [ActiveRecord::DatabaseConfigurations]
          def database_configurations
            return @database_configurations if defined?(@database_configurations)

            config_yaml = load_from_database_yaml!
            ActiveRecord::Base.configurations = config_yaml

            @database_configurations = ActiveRecord::Base.configurations
                                                         .configs_for(env_name: context.env, include_hidden: false)
          end

          def load_from_database_yaml!
            YAML.load_file(context.database_config_file_path, aliases: true)
          rescue Errno::ENOENT
            raise Gitlab::Backup::Cli::Errors::DatabaseConfigMissingError, context.database_config_file_path
          end
        end
      end
    end
  end
end

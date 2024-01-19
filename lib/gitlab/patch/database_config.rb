# frozen_string_literal: true

require_relative '../popen'

# The purpose of this code is to set the migrations path
# for the Geo tracking database and the embedding database.
module Gitlab
  module Patch
    module DatabaseConfig
      extend ActiveSupport::Concern

      CommandExecutionError = Class.new(StandardError)

      def database_configuration
        super.to_h do |env, configs|
          parsed_config = parse_extra_config(configs)

          if Gitlab.ee?
            ee_databases = %w[embedding geo]

            ee_databases.each do |ee_db_name|
              next unless parsed_config.key?(ee_db_name)

              migrations_paths = Array(parsed_config[ee_db_name]['migrations_paths'])
              migrations_paths << File.join('ee', 'db', ee_db_name, 'migrate') if migrations_paths.empty?
              migrations_paths << File.join('ee', 'db', ee_db_name, 'post_migrate') unless ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS']

              parsed_config[ee_db_name]['migrations_paths'] = migrations_paths.uniq
              parsed_config[ee_db_name]['schema_migrations_path'] = File.join('ee', 'db', ee_db_name, 'schema_migrations') if parsed_config[ee_db_name]['schema_migrations_path'].blank?
            end
          end

          [env, parsed_config]
        end
      end

      private

      def parse_extra_config(configs)
        command = configs.delete('config_command')
        return configs unless command.present?

        config_from_command = extra_config_from_command(command)
        return configs unless config_from_command.present?

        configs.deep_merge(config_from_command)
      end

      def extra_config_from_command(command)
        cmd = command.split(" ")
        output, exit_status = Gitlab::Popen.popen(cmd)

        if exit_status != 0
          raise CommandExecutionError,
            "database.yml: Execution of `#{command}` failed with exit code #{exit_status}. Output: #{output}"
        end

        parsed_output = YAML.safe_load(output)

        unless parsed_output.is_a?(Hash)
          raise CommandExecutionError,
            "database.yml: The output of `#{command}` must be a Hash, #{parsed_output.class} given. Output: #{parsed_output}"
        end

        parsed_output.deep_stringify_keys
      rescue Psych::SyntaxError => e
        error_message = <<~MSG
          database.yml: Execution of `#{command}` generated invalid yaml.
          Error: #{e.problem} #{e.context} at line #{e.line} column #{e.column}
        MSG

        raise CommandExecutionError, error_message
      end
    end
  end
end

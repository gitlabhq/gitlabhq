# frozen_string_literal: true

module Gitlab
  module Redis
    class ConfigGenerator
      CommandExecutionError = Class.new(StandardError)

      attr_reader :component

      def initialize(component = 'Redis')
        @component = component
      end

      def generate(original_config)
        command = original_config.delete(:config_command)
        return original_config unless command.present?

        config_from_command = generate_yaml_from_command(command)
        return original_config unless config_from_command.present?

        original_config.deep_merge(config_from_command)
      end

      private

      def generate_yaml_from_command(command)
        cmd = command.split(" ")
        output, exit_status = Gitlab::Popen.popen(cmd)

        if exit_status != 0
          raise CommandExecutionError,
            "#{component}: Execution of `#{command}` failed with exit code #{exit_status}." \
              "Output: #{output}"
        end

        parsed_output = YAML.safe_load(output)

        unless parsed_output.is_a?(Hash)
          raise CommandExecutionError,
            "#{component}: The output of `#{command}` must be a Hash, #{parsed_output.class} given." \
              "Output: #{parsed_output}"
        end

        parsed_output.deep_symbolize_keys
      rescue Psych::SyntaxError => e
        error_message = <<~MSG
          #{component}: Execution of `#{command}` generated invalid yaml.
          Error: #{e.problem} #{e.context} at line #{e.line} column #{e.column}
        MSG
        raise CommandExecutionError, error_message
      end
    end
  end
end

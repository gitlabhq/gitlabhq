# frozen_string_literal: true

module Gitlab
  module Redis
    class ConfigGenerator
      CommandExecutionError = Class.new(StandardError)
      InvalidPathError = Class.new(StandardError)

      attr_reader :component

      def self.parse_client_tls_options(config)
        return config unless config&.key?(:ssl_params)

        # Only cert_file and key_file are handled in this method. ca_file and
        # ca_path are Strings, so they can be passed as-is. cert_store is not
        # currently supported. Note that this is no longer needed now that
        # redis-client does this conversion for us with the cert and key parameters,
        # but preserve this for backwards compatibility.
        cert_file = config[:ssl_params].delete(:cert_file)
        key_file = config[:ssl_params].delete(:key_file)

        if cert_file
          unless ::File.exist?(cert_file)
            raise InvalidPathError,
              "Certificate file #{cert_file} specified in Redis configuration does not exist."
          end

          config[:ssl_params][:cert] = OpenSSL::X509::Certificate.new(File.read(cert_file))
        end

        if key_file
          unless ::File.exist?(key_file)
            raise InvalidPathError,
              "Key file #{key_file} specified in Redis configuration does not exist."
          end

          config[:ssl_params][:key] = OpenSSL::PKey.read(File.read(key_file))
        end

        config
      end

      def initialize(component = 'Redis')
        @component = component
      end

      def generate(original_config)
        command = original_config.delete(:config_command)
        config = if command.present?
                   config_from_command = generate_yaml_from_command(command)
                   config_from_command.present? ? original_config.deep_merge(config_from_command) : original_config
                 else
                   original_config
                 end

        self.class.parse_client_tls_options(config)
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

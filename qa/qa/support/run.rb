# frozen_string_literal: true

require 'open3'
require 'timeout'

module QA
  module Support
    module Run
      include QA::Support::Repeater

      CommandError = Class.new(StandardError)
      CommandTimeoutError = Class.new(CommandError)

      Result = Struct.new(:command, :exitstatus, :response) do
        alias_method :to_s, :response

        def success?
          exitstatus == 0 && !response.include?('Error encountered') # rubocop:disable Rails/NegateInclude
        end

        def to_i
          response.to_i
        end
      end

      def run(
        command_str,
        raise_on_failure: true,
        env: [],
        max_attempts: 1,
        sleep_internal: 0,
        log_prefix: '',
        timeout: nil
      )
        command = [*env, command_str, '2>&1'].compact.join(' ')
        result = nil

        repeat_until(
          max_attempts: max_attempts,
          sleep_interval: sleep_internal,
          raise_on_failure: false
        ) do
          Runtime::Logger.debug "#{log_prefix}pwd=[#{Dir.pwd}], command=[#{command}]"

          begin
            output, status = timeout ? Timeout.timeout(timeout) { Open3.capture2e(command) } : Open3.capture2e(command)
            output.chomp!
            Runtime::Logger.debug "#{log_prefix}output=[#{output}], exitstatus=[#{status.exitstatus}]"

            result = Result.new(command, status.exitstatus, output)
            result.success?
          rescue Timeout::Error
            Runtime::Logger.debug "#{log_prefix}command timed out after #{timeout} seconds"
            raise CommandTimeoutError, "The command #{command} timed out after #{timeout} seconds"
          end
        end

        raise_error = raise_on_failure && !result.success?

        if raise_error
          raise CommandError,
            "The command #{result.command} failed (#{result.exitstatus}) " \
              "with the following output:\n#{result.response}"
        end

        result
      end
    end
  end
end

QA::Support::Run.prepend_mod_with("Support::Run", namespace: QA)

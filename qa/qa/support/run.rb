# frozen_string_literal: true

require 'open3'

module QA
  module Support
    module Run
      include QA::Support::Repeater

      CommandError = Class.new(StandardError)

      Result = Struct.new(:command, :exitstatus, :response) do
        alias_method :to_s, :response

        def success?
          exitstatus == 0 && !response.include?('Error encountered') # rubocop:disable Rails/NegateInclude
        end

        def to_i
          response.to_i
        end
      end

      def run(command_str, raise_on_failure: true, env: [], max_attempts: 1, sleep_internal: 0, log_prefix: '')
        command = [*env, command_str, '2>&1'].compact.join(' ')
        result = nil

        repeat_until(max_attempts: max_attempts, sleep_interval: sleep_internal, raise_on_failure: false) do
          Runtime::Logger.debug "#{log_prefix}pwd=[#{Dir.pwd}], command=[#{command}]"
          output, status = Open3.capture2e(command)
          output.chomp!
          Runtime::Logger.debug "#{log_prefix}output=[#{output}], exitstatus=[#{status.exitstatus}]"

          result = Result.new(command, status.exitstatus, output)

          result.success?
        end

        raise_error = raise_on_failure && !result.success?

        if raise_error
          raise CommandError,
            "The command #{result.command} failed (#{result.exitstatus}) with the following output:\n#{result.response}"
        end

        result
      end
    end
  end
end

QA::Support::Run.prepend_mod_with("Support::Run", namespace: QA)

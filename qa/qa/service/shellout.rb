# frozen_string_literal: true

require 'open3'

module QA
  module Service
    module Shellout
      using Rainbow

      CommandError = Class.new(StandardError)

      module_function

      def shell(command, stdin_data: nil, fail_on_exception: true, stream_progress: true, mask_secrets: [], return_exit_status: false) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        cmd_string = Array(command).join(' ')
        cmd_output = ''
        exit_status = 0

        QA::Runtime::Logger.info("Executing: `#{mask_secrets_on_string(cmd_string, mask_secrets).cyan}`")

        Open3.popen2e(*command) do |stdin, out, wait|
          stdin.puts(stdin_data) if stdin_data
          stdin.close if stdin_data

          print_progress_dots = stream_progress && !Runtime::Env.running_in_ci?

          out.each do |line|
            line = mask_secrets_on_string(line, mask_secrets)

            cmd_output += line
            yield line if block_given?

            # indicate progress for local run by printing dots
            print "." if print_progress_dots
          end

          # add newline after progress dots
          puts if print_progress_dots && !cmd_output.empty?

          exit_status = wait.value.exitstatus if wait.value.exited?

          if exit_status.nonzero? && fail_on_exception
            Runtime::Logger.error("Command output:\n#{cmd_output.strip}") unless cmd_output.empty?
            raise CommandError, "Command: `#{mask_secrets_on_string(cmd_string, mask_secrets)}` failed! ✘"
          end

          Runtime::Logger.debug("Command output:\n#{cmd_output.strip}") unless cmd_output.empty?
        end

        return_exit_status ? [cmd_output.strip, exit_status] : cmd_output.strip
      end

      def sql_to_docker_exec_cmd(sql, username, password, database, host, container)
        <<~CMD
          docker exec --env PGPASSWORD=#{password} #{container} \
            bash -c "psql -U #{username} -d #{database} -h #{host} -c \\"#{sql}\\""
        CMD
      end

      def wait_until_shell_command(cmd, **kwargs)
        sleep_interval = kwargs.delete(:sleep_interval) || 1
        stream_progress = kwargs.delete(:stream_progress).then { |arg| arg.nil? ? true : false }

        Support::Waiter.wait_until(sleep_interval: sleep_interval, **kwargs) do
          shell(cmd, stream_progress: stream_progress) do |line|
            break true if yield line
          end
        end
      end

      def wait_until_shell_command_matches(cmd, regex, **kwargs)
        wait_until_shell_command(cmd, stream_progress: false, **kwargs) do |line|
          line =~ regex
        end
      end

      def mask_secrets_on_string(str, secrets)
        secrets.reduce(str) { |s, secret| s.gsub(secret, '****') }
      end
    end
  end
end

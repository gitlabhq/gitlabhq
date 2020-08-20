# frozen_string_literal: true

require 'open3'

module QA
  module Service
    module Shellout
      CommandError = Class.new(StandardError)

      module_function

      ##
      # TODO, make it possible to use generic QA framework classes
      # as a library - gitlab-org/gitlab-qa#94
      #
      def shell(command, stdin_data: nil)
        puts "Executing `#{command}`"

        Open3.popen2e(*command) do |stdin, out, wait|
          stdin.puts(stdin_data) if stdin_data
          stdin.close if stdin_data

          if block_given?
            out.each do |line|
              yield line
            end
          end

          out.each_char { |char| print char }

          if wait.value.exited? && wait.value.exitstatus.nonzero?
            raise CommandError, "Command `#{command}` failed!"
          end
        end
      end

      def sql_to_docker_exec_cmd(sql, username, password, database, host, container)
        <<~CMD
          docker exec --env PGPASSWORD=#{password} #{container} \
            bash -c "psql -U #{username} -d #{database} -h #{host} -c \\"#{sql}\\""
        CMD
      end

      def wait_until_shell_command(cmd, **kwargs)
        sleep_interval = kwargs.delete(:sleep_interval) || 1

        Support::Waiter.wait_until(sleep_interval: sleep_interval, **kwargs) do
          shell cmd do |line|
            break true if yield line
          end
        end
      end

      def wait_until_shell_command_matches(cmd, regex, **kwargs)
        wait_until_shell_command(cmd, kwargs) do |line|
          QA::Runtime::Logger.debug(line.chomp)

          line =~ regex
        end
      end
    end
  end
end

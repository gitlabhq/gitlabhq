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
          out.each_char { |char| print char }

          if wait.value.exited? && wait.value.exitstatus.nonzero?
            raise CommandError, "Command `#{command}` failed!"
          end
        end
      end
    end
  end
end

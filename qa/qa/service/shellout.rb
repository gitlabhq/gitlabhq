require 'open3'

module QA
  module Service
    module Shellout
      CommandError = Class.new(StandardError)

      ##
      # TODO, make it possible to use generic QA framework classes
      # as a library - gitlab-org/gitlab-qa#94
      #
      def shell(command)
        puts "Executing `#{command}`"

        Open3.popen2e(command) do |_in, out, wait|
          out.each { |line| puts line }

          if wait.value.exited? && wait.value.exitstatus.nonzero?
            raise CommandError, "Command `#{command}` failed!"
          end
        end
      end
    end
  end
end

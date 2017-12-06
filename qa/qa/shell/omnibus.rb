require 'open3'

module QA
  module Shell
    class Omnibus
      include Scenario::Actable

      def initialize(container)
        @name = container
      end

      def gitlab_ctl(command, input: nil)
        if input.nil?
          shell "docker exec #{@name} gitlab-ctl #{command}"
        else
          shell "docker exec #{@name} bash -c '#{input} | gitlab-ctl #{command}'"
        end
      end

      private

      ##
      # TODO, make it possible to use generic QA framework classes
      # as a library - gitlab-org/gitlab-qa#94
      #
      def shell(command)
        puts "Executing `#{command}`"

        Open3.popen2e(command) do |_in, out, wait|
          out.each { |line| puts line }

          if wait.value.exited? && wait.value.exitstatus.nonzero?
            raise "Docker command `#{command}` failed!"
          end
        end
      end
    end
  end
end

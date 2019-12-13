# frozen_string_literal: true

module QA
  module Service
    class Omnibus
      include Scenario::Actable
      include Service::Shellout

      def initialize(container)
        @name = container
      end

      def gitlab_ctl(command, input: nil)
        docker_exec("gitlab-ctl #{command}", input: input)
      end

      def docker_exec(command, input: nil)
        command = "#{input} | #{command}" if input
        shell "docker exec #{@name} bash -c '#{command}'"
      end
    end
  end
end

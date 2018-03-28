module QA
  module Service
    class Omnibus
      include Scenario::Actable
      include Service::Shellout

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

      def gitlab_rake(command, input: nil)
        if input.nil?
          shell "docker exec #{@name} gitlab-rake #{command}"
        else
          shell "docker exec #{@name} bash -c '#{input} | gitlab-rake #{command}'"
        end
      end
    end
  end
end

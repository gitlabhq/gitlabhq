module QA
  module Service
    class Omnibus
      include Gitlab::QA::Framework::Scenario::Actable

      def initialize(container)
        @name = container
      end

      def gitlab_ctl(command, input: nil)
        cmd =
          if input.nil?
            "docker exec #{@name} gitlab-ctl #{command}"
          else
            "docker exec #{@name} bash -c '#{input} | gitlab-ctl #{command}'"
          end

        Gitlab::QA::Framework::Docker::Shellout.new(cmd).execute!
      end
    end
  end
end
